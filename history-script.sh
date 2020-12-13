#!/bin/bash
# goes through git history, oldest to newest, and creates a database of popularity data for addons overtime
set -e

catalogue=${1:-"full-catalogue.json"}

# clean up from any previous runs
git checkout master
rm -f "*.json.prev" history.sqlite3

# list of commit references, oldest to newest
ref_list=$(git log  --reverse | grep '^commit' | cut -c 8-)

# checkout ref, call script with ref, timestamp and catalogue files
for ref in $ref_list; do
    git checkout "$ref" --quiet
    timestamp=$(TZ=UTC git --no-pager log -1 --format=%cd --date=iso-strict-local)
    echo "$timestamp: $ref"
    python history-script.py "$timestamp" "$catalogue" "$catalogue.prev"
    # so the next iteration reads from previous iteration's catalogue
    cp "$catalogue" "$catalogue.prev"
    echo "---"
done

sqlite3 history.sqlite3 "select sum(count_difference) as pop, source, source_id as 'source-id', name from addon where source = 'curseforge' group by source, source_id, name order by pop desc limit 50;" -json > most-popular-curseforge.json
echo "wrote most-popular-curseforge.json"

sqlite3 history.sqlite3 "select sum(count_difference) as pop, source, source_id as 'source-id', name from addon where source = 'wowinterface' group by source, source_id, name order by pop desc limit 50;" -json > most-popular-wowinterface.json
echo "wrote most-popular-wowinterface.json"

rm -f "$catalogue.prev"
git checkout master
