#!/bin/bash
set -eux

this_dir="$(pwd)"
home_dir="$this_dir/xdg-home"

export XDG_DATA_HOME="$home_dir/data"
export XDG_CONFIG_HOME="$home_dir/config"

mkdir -p "$home_dir"

if [ ! -d strongbox ]; then
    git clone --branch strongbox https://github.com/ogri-la/wowman strongbox
else
    (
        cd strongbox
        git reset --hard
        git pull
    )
fi

(
    cd strongbox
    lein run - --action scrape-catalogue
)

cp "$home_dir/data/strongbox/"*-catalogue.json .
git commit -m "catalogue update"
