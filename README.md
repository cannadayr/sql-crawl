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
