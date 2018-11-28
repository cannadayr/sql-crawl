#!/bin/bash
#TODO combine w/ cte in crawl.sql
query="\
    select load_extension('sqlitepipe/sqlitepipe'); \
    select \
        page.url \
    from whitelist \
\
    left outer join ( \
        select \
            url, \
            printf(\"%s\",pipe('uri-parser/uri-parser --protocol --host ' || quote(page.url) || ' | awk ''BEGIN{FS=\" \"} {printf \$1 \"://\" \$2 }''')) as domain \
\
        from page \
\
        where content is null
\
        and is_retired is not 1 \
\
    ) page on page.domain = whitelist.domain \
\
    where page.url is not null \
    limit 1 \
;"
url="$(printf "%s" "${query}" | sqlite3 pages.db | tr -d '\n')"

# clear page_rank table
# clear tmp_rank table
# clear out_degree table
clear_query="\
    begin transaction; \
    delete from out_degree; \
    delete from page_rank; \
    delete from tmp_rank; \
    commit; \
"

# computes out-degrees
# NOTE- every page in graph must have an out-degree!
out_degree_init=" \
    begin transaction; \
    insert into out_degree \
    select \
        page.id, \
        count(link.src_page_id) \
    from page \
    left outer join link on link.src_page_id = page.id \
    group by page.id; \
    commit; \
"

alpha="0.8"
page_rank_init=" \
    begin transaction; \
    insert into page_rank (id,rank) \
    select \
        page.id, \
        (1 - ${alpha}) / (select count(*) from page) as rank \
    from page \
    inner join out_degree on out_degree.id = page.id; \
    commit;
"

page_rank_compute=" \
    begin transaction; \
    insert into tmp_rank \
    select \
        link.dest_page_id, \
        sum(${alpha} * page_rank.rank / out_degree.degree) \
        + (1 - ${alpha}) / (select count(*) from page) as rank \
    from page_rank \
    inner join link on link.src_page_id = page_rank.id \
    inner join out_degree on out_degree.id = page_rank.id \
    group by link.dest_page_id; \
\
    delete from page_rank; \
    insert into page_rank \
    select * from tmp_rank; \
    delete from tmp_rank; \
    commit; \
"


count=0
echo "url = ${url}"
while test -n "${url}" && test "${count}" -lt 100
do
    count=$(echo "${count} + 1" | bc)
    #echo "${count}"
    sqlite3 pages.db < crawl.sql | sqlite3 -echo pages.db
    echo
    #TODO dynamically determine delay
    sleep 30

    # clear pagerank related tables
    printf "%s" "${clear_query}" | sqlite3 -echo pages.db

    # init out_degree
    printf "%s" "${out_degree_init}" | sqlite3 -echo pages.db

    # init page_rank
    printf "%s" "${page_rank_init}" | sqlite3 -echo pages.db

    # compute page_rank
    iter=1

    while test "${iter}" -lt 5
    do
        printf "%s" "${page_rank_compute}" | sqlite3 -echo pages.db
        iter=$(echo "${iter} + 1" | bc)
    done

    # check if we still have a url to crawl
    url="$(printf "%s" "${query}" | sqlite3 -echo pages.db | tr -d '\n')"
done

