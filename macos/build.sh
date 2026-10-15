#!/bin/sh
# Build Stripes.saver (universal) and install it into ~/Library/Screen Savers.
# Usage: build.sh [install | release | pkg]. "release" notarizes the saver and zips it;
# "pkg" does the same and also builds a signed, notarized installer package.
set -eu
cd "$(dirname "$0")"

out=build/Stripes.saver
rm -rf build
mkdir -p "$out/Contents/MacOS" "$out/Contents/Resources"

# The Command Line Tools lack the Intel slice of a Swift support library; a full Xcode has it.
if [ -z "${DEVELOPER_DIR:-}" ] && ! xcode-select -p | grep -q '\.app/'; then
    for x in /Applications/Xcode.app /Applications/Xcode-beta.app; do
        if [ -d "$x" ]; then export DEVELOPER_DIR="$x/Contents/Developer"; break; fi
    done
fi

for arch in arm64 x86_64; do
    xcrun swiftc -O -emit-library -module-name Stripes \
        -target "$arch-apple-macos13" \
        -framework ScreenSaver -framework AppKit \
        -o "build/Stripes-$arch" *.swift
done
lipo -create build/Stripes-arm64 build/Stripes-x86_64 -output "$out/Contents/MacOS/Stripes"
rm build/Stripes-arm64 build/Stripes-x86_64

cp Info.plist "$out/Contents/"
cp ../data/stripes.json "$out/Contents/Resources/"

# System Settings reads the thumbnail only from a TIFF holding both resolutions.
tiffutil -cathidpicheck Resources/thumbnail.png Resources/thumbnail@2x.png \
    -out "$out/Contents/Resources/thumbnail.tiff" >/dev/null

if [ "${1:-}" = release ] || [ "${1:-}" = pkg ]; then
    codesign --force --options runtime --timestamp \
        --sign "Developer ID Application: Georgios Karamanis (N4B5PD6UN5)" "$out"

    # notarytool needs an archive; the stapled bundle is zipped again for release.
    version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)
    zip="build/Stripes-$version.zip"
    ditto -c -k --keepParent "$out" "$zip"
    xcrun notarytool submit "$zip" --keychain-profile stripes-notary --wait
    xcrun stapler staple "$out"
    rm "$zip"
    ditto -c -k --keepParent "$out" "$zip"
    xcrun stapler validate "$out"
    echo "Notarized: $zip"
else
    codesign --force --sign - "$out"
fi

if [ "${1:-}" = pkg ]; then
    work=build/pkg
    mkdir -p "$work/root"
    ditto "$out" "$work/root/Stripes.saver"

    # Not relocatable, so the installer never writes over a copy it finds somewhere else.
    pkgbuild --analyze --root "$work/root" "$work/component.plist" >/dev/null
    plutil -replace 0.BundleIsRelocatable -bool NO "$work/component.plist"
    mkdir -p "$work/scripts"
    cp pkg/postinstall "$work/scripts/"
    chmod +x "$work/scripts/postinstall"
    pkgbuild --root "$work/root" --component-plist "$work/component.plist" \
        --scripts "$work/scripts" --identifier is.karaman.stripes-saver --version "$version" \
        --install-location "/Library/Screen Savers" "$work/Stripes.pkg"

    # The user picks this Mac or only their own account; the second needs no admin password.
    cat > "$work/distribution.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>Stripes</title>
    <domains enable_anywhere="false" enable_currentUserHome="true" enable_localSystem="true"/>
    <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
    <volume-check><allowed-os-versions><os-version min="13.0"/></allowed-os-versions></volume-check>
    <choices-outline><line choice="default"/></choices-outline>
    <choice id="default" title="Stripes"><pkg-ref id="is.karaman.stripes-saver"/></choice>
    <pkg-ref id="is.karaman.stripes-saver" version="$version">Stripes.pkg</pkg-ref>
</installer-gui-script>
EOF

    pkg="build/Stripes-$version.pkg"
    productbuild --distribution "$work/distribution.xml" --package-path "$work" \
        --sign "Developer ID Installer: Georgios Karamanis (N4B5PD6UN5)" --timestamp "$pkg"
    rm -rf "$work"
    xcrun notarytool submit "$pkg" --keychain-profile stripes-notary --wait
    xcrun stapler staple "$pkg"
    spctl -a -vv -t install "$pkg"
    echo "Notarized: $pkg"
fi

if [ "${1:-}" = install ]; then
    dest="$HOME/Library/Screen Savers/Stripes.saver"
    [ -e "$dest" ] && trash "$dest"
    cp -R "$out" "$dest"

    # The saver host caches the old bundle until it restarts.
    killall legacyScreenSaver 2>/dev/null || true
    echo "Installed to $dest"
fi
