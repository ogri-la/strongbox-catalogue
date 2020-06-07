#!/bin/bash
set -eux

this_dir="$(pwd)"
home_dir="$this_dir/xdg-home"

export XDG_DATA_HOME="$home_dir/data"
export XDG_CONFIG_HOME="$home_dir/config"

mkdir -p "$home_dir"

if [ ! -d strongbox ]; then
    git clone https://github.com/ogri-la/strongbox
fi

(
    cd strongbox
    git reset --hard
    git checkout develop
    git pull

    # update ogri-la/strongbox-catalogue
    lein run - --action scrape-catalogue
)
cp "$home_dir/data/strongbox/"*-catalogue.json .
# (commit!)

# tell wowman to use the strongbox cache data
(
    cd "$home_dir/data/"
    rm -rf wowman/cache
    ln -s "$home_dir/data/strongbox/cache/" "$home_dir/data/wowman/cache"
)

# update ogri-la/wowman-data
(
    cd strongbox
    git reset --hard
    git checkout wowman
    lein run - --action scrape-catalog
)

cp "$home_dir/data/wowman/"*-catalogue.json ../wowman-data/
# (commit!)
