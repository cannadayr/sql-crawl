#!/bin/bash
sqlite3 pages.db < <(autom4te -l m4sugar crawl.sql.m4)
