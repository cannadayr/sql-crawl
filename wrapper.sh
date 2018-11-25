#!/bin/bash
#TODO combine w/ cte in crawl.sql
query="
    select load_extension('sqlitepipe/sqlitepipe');
    select \
        url \
    from whitelist \
\
    left outer join ( \
        select \
            url, \
            printf(\"%s\",pipe('sed ''s/^.*:\/\///'' | sed ''s/\([^\/]*\)\/.*/\1/'' | awk -F\".\" ''{printf \$(NF-1) \".\" \$NF}''',page.url)) as domain \
\
        from page \
\
        where content is null
\
        and is_retired is not 1 \
\
    ) page on page.domain = whitelist.domain \
\
    limit 1 \
;"
url="$(printf "%s" "${query}" | sqlite3 pages.db | tr -d '\n')"

echo "url = ${url}"
while test -n "${url}"
do
    sqlite3 pages.db < crawl.sql | sqlite3 -echo pages.db
    echo
    sleep 1
    url="$(printf "%s" "${query}" | sqlite3 pages.db | tr -d '\n')"
    echo "url = ${url}"
done
