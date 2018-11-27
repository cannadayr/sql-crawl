#!/bin/bash

iter=1

while test "${iter}" -lt 50
do
    echo "${iter}"
    sqlite3 -echo links.db < <(autom4te -l m4sugar rank.sql)
    iter=$(echo "${iter} + 1" | bc)
done
