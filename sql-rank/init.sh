#!/bin/bash
rm links.db \
    && sqlite3 links.db < schema.sql \
    && sqlite3 links.db < seed_data.sql \
    && sqlite3 links.db < compute_out_degree.sql \
    && sqlite3 links.db < <(autom4te -l m4sugar pagerank_init.sql)

