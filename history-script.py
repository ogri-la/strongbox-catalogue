import os, sys, json
import sqlite3

database = 'history.sqlite3'

def select_keys(data, key_list):
    return [data[key] for key in key_list]

def keyfn(addon):
    return (addon['source'], addon['source-id'])

def mkidx(addon_list):
    return {keyfn(addon):addon for addon in addon_list}

def popularity_data(curr_addon, prev_addon):
    num = curr_addon['download-count']
    prev_num = prev_addon.get('download-count', num)
    diff = num - prev_num
    return {
        'count': num,
        'count_difference': diff
    }

def db_connection():
    return sqlite3.connect(database)

def insert(db, addon):
    sql = """INSERT INTO addon 
        (timestamp, source, source_id, name, count, count_difference)
    VALUES
        (?,?,?,?,?,?);"""
    data = select_keys(addon, ['timestamp', 'source', 'source-id', 'name', 'count', 'count_difference'])
    db.execute(sql, tuple(data))

def init_db():
    db = sqlite3.connect(database)
    sql = """
        CREATE TABLE addon(
            timestamp DATETIME NOT NULL,
            source TEXT NOT NULL,
            source_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            count INTEGER NOT NULL,
            count_difference INTEGER NOT NULL,
            
            PRIMARY KEY (timestamp, source, source_id)
        );"""
    db.execute(sql)
    db.commit()

def main(timestamp, curr_catalogue_fname, prev_catalogue_fname):
    curr_catalogue = json.load(open(curr_catalogue_fname, 'r'))
    prev_catalogue = {'addon-summary-list': []}
    # previous catalogue won't exist on first call to script.
    if os.path.exists(prev_catalogue_fname):
        prev_catalogue = json.load(open(prev_catalogue_fname, 'r'))

    addon_list = curr_catalogue['addon-summary-list']
    prev_addon_idx = mkidx(prev_catalogue['addon-summary-list'])
    
    if not os.path.exists(database):
        init_db()
    
    db = db_connection()
    for addon in addon_list:
        addon_key = keyfn(addon)
        addon.update(popularity_data(addon, prev_addon_idx.get(addon_key, {})))
        addon['timestamp'] = timestamp
        insert(db, addon)
    db.commit()

if __name__ == '__main__':
    main(*sys.argv[1:4])
