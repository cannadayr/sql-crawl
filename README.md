## Overview
A minimal web spider and indexer

USE AT YOUR OWN RISK - possibly unsafe

Currently implemented:
* robots.txt disallow rules (untested)
* pagerank (needs tuning)

## Dependencies
* lynx
* sqlite3
* libsqlite3-dev
* sqlitepipe

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
* initialize robots.txt for a domain (no trailing backslash!)
```
./robo-parse.sh https://example.com
```

## Usage
```
./wrapper.sh
```
## Dependencies
* libsqlite3-dev

## TODO
* more thorough robots.txt testing
    * add in 'allow' logic
* respect 429 ratelimit responses
* respect 'crawl-delay' rules
* consolidate whitelist query in wrapper.sh w/ CTE in crawl.sql
* add full text search
* add bayesian spam filtering
* tuning of PageRank's 'alpha' parameter & iteration count

## PageRank Attribution
Taken from the [Stack Overflow network](https://stackoverflow.com)

[Original question](https://stackoverflow.com/questions/17787944/sql-pagerank-implementation)

Answer provided by: [Geng Liang](https://stackoverflow.com/users/5914124/geng-liang)

[Attribution details](https://stackoverflow.blog/2009/06/25/attribution-required/)
