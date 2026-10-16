#!/bin/sh
# Builds the Steam screensaver into build/stripes and zips it.
#
#   steam/build.sh                 build build/stripes and build/Stripes-steam.zip
#   steam/build.sh deck <host>     build, then copy it to a Steam Deck over ssh
#
# The data goes in as stripes.js, a script, so the page needs no fetch.

set -eu
cd "$(dirname "$0")"

# The folder name becomes part of a hostname, which Chromium lowercases, and Steam then
# looks the folder up case-sensitively. A name with capitals fails with error -105.
out=build/stripes
rm -rf build
mkdir -p "$out"
cp src/index.html src/main.css src/main.js src/config.js "$out/"
{
    printf 'const STRIPES = '
    cat ../data/stripes.json
    printf ';\n'
} > "$out/stripes.js"
(cd build && zip -qr Stripes-steam.zip stripes)
echo "Built $out and build/Stripes-steam.zip"

if [ "${1:-}" = deck ]; then
    host=${2:?usage: build.sh deck <host>}
    dest='.steam/root/config/uioverrides/screensavers'
    ssh "$host" "mkdir -p ~/$dest/stripes"
    scp -q "$out/index.html" "$out/main.css" "$out/main.js" "$out/stripes.js" "$host:$dest/stripes/"

    # An existing config.js holds the options set on the Deck, so it stays.
    if ! ssh "$host" "test -e ~/$dest/stripes/config.js"; then
        scp -q "$out/config.js" "$host:$dest/stripes/"
    fi
    echo "Copied to $host:~/$dest/stripes. Pick it in Settings > Customization > Screensaver."
fi
