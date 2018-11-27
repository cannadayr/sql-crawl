#!/bin/bash
rm links.db \
    && sqlite3 links.db < schema.sql \
    && sqlite3 links.db < seed_data.sql \
    && sqlite3 links.db < compute_out_degree.sql

