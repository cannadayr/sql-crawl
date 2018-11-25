## Overview
A simple crawler that uses sqlitepipe & lynx to recursively crawl whitelisted domains

USE AT YOUR OWN RISK - possibly unsafe

## Setup
* fill out seed_data.sql (see sample_seed_data.sql)
* compile sqlitepipe extension
```
cd sqlitepipe/ && make
```
* initialize schema and seed_data
```
sqlite3 pages.db < schema.sql && sqlite3 pages.db < seed_data.sql
```

## Usage
```
./wrapper.sh
```
## Dependencies
* libsqlite3-dev

## TODO
* respect robots.txt
* better link verification before crawling
* consolidate whitelist query in wrapper.sh w/ CTE in crawl.sql
* add full text search
* add bayesian spam filtering
* add pagerank (or equivalent) algorithm for link prioritization

