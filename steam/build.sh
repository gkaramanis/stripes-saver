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

# locations.txt lists every name config.js accepts, named the way main.js names them.
# It ships next to config.js and is kept in the repo for linking.
jq -r '
    .locations
    | map({ region, country, place,
            name: (if .country == "" then .region
                   elif .place == "" then .country
                   else "\(.place), \(.country)" end) })
    | group_by(.region)
    | sort_by(.[0].region != "Global", .[0].region)
    | "Stripes locations\n\nEvery location the screensaver can show, by region. Each country comes first,\nfollowed by its cities. Copy a name, quotes included, into locations in config.js:\n\n    locations: [\"Global\", \"Sweden\", \"Stockholm, Sweden\"],\n",
      (.[] | "\(.[0].region)\n\n"
             + (sort_by((.country | ascii_downcase), (.place | ascii_downcase))
                | map("\"\(.name)\"") | join("\n")) + "\n")
' ../data/stripes.json > locations.txt
cp locations.txt "$out/"

(cd build && zip -qr Stripes-steam.zip stripes)
echo "Built $out and build/Stripes-steam.zip"

if [ "${1:-}" = deck ]; then
    host=${2:?usage: build.sh deck <host>}
    dest='.steam/root/config/uioverrides/screensavers'
    ssh "$host" "mkdir -p ~/$dest/stripes"
    scp -q "$out/index.html" "$out/main.css" "$out/main.js" "$out/stripes.js" "$out/locations.txt" "$host:$dest/stripes/"

    # An existing config.js holds the options set on the Deck, so it stays.
    if ! ssh "$host" "test -e ~/$dest/stripes/config.js"; then
        scp -q "$out/config.js" "$host:$dest/stripes/"
    fi
    echo "Copied to $host:~/$dest/stripes. Pick it in Settings > Customization > Screensaver."
fi
