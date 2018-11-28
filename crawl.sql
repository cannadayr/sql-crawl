.load sqlitepipe/sqlitepipe

with whitelisted_url(id,domain,url,path,rank) as (
   select
        whitelist.id,
        whitelist.domain,
        --page.id,
        page.url,
        page.path,
        page_rank.rank
    from whitelist

    left outer join (
        select
            id,
            url,
            printf("%s",pipe('uri-parser/uri-parser --protocol --host ' || quote(page.url) || ' \
                                | awk ''BEGIN{FS=" "} {printf $1 "://" $2}''')
            ) as domain,
            printf("%s",pipe('uri-parser/uri-parser --path --query ' || quote(page.url) || ' \
                                | awk ''BEGIN{FS=" "} {if($1==$2){print $1;}else{print $1 " " $2;}}'' \
                                | tr -d ''\n'' | tr '' '' ?')
            ) as path

        from page

        where content is null -- TODO add a last_fetched field and query-by

        and is_retired is not 1

    ) page on page.domain = whitelist.domain

    left join page_rank on page_rank.id = page.id

    where page.url is not null

    order by page_rank.rank desc

    limit 1
),
-- TODO this is only working on whitelisted_url, NOT every link we get from it #fixme
-- maybe we could not return the globbed pattern and join on it as-needed?
disallow_rules(pattern,is_match) as (
    select
        pattern,
        glob(pattern || '*' ,(select path from whitelisted_url)) as is_match
    from rule

    where
        whitelist_id = (select id from whitelisted_url)
        and is_allowed = 0
),
disallow_match(num_matches) as (
    select
        count(is_match)
    from
        disallow_rules
    where is_match = "1"
),
fetch_content(url,full_content) as (
    select
        url,
        case when (
            (select num_matches from disallow_match) >= 1
        ) then printf("%s","") -- just return the empty str and we'll catch it later
        else
            -- the '-nonumbers' options might help w/ full-text search
            -- however it removes the 'Reference' delimiter making separating links & content easier
            -- TODO we might want to add in hiddenlinks later
            -- TODO handle response code
            pipe('lynx -dump -nostatus -notitle -unique_urls --hiddenlinks=ignore ' || quote(url))
        end as full_content

    from whitelisted_url
),
-- gets the content from lynx's output
parse_content(url,content) as (
    select
        url,
        -- can't quote full_content
        printf("%s",pipe('tac | sed ''0,/^References/d'' | tac',full_content)) as content

    from fetch_content
),
-- gets the links from lynx's output
parse_links(url,links) as (
    select
        url,
        printf("%s",pipe('tac | sed ''/^References/q'' | head -n -2 | sed ''s/\s\+[0-9]\+\.\s//'' \
| while IFS= read -r line; \
do \
    uri-parser/uri-parser  --protocol --host "${line}" \
        | awk ''BEGIN{ret=1} {if(NF==2){ret=0;}} END{exit ret}'' && { \
            uri-parser/uri-parser --defragment "${line}"; \
        } \
done; true',full_content)) as links

    from fetch_content
),
link_inserts(link_insert_queries) as (
    select
        case when (
            (select num_matches from disallow_match) >= 1
        ) then printf("%s","") -- just return the empty str and we'll catch it later
        else
            printf("%s",pipe('awk ''{print \
                                "insert into page (url) values (\x27" $1 "\x27);\n" \
                                "insert into link (src_page_id,dest_page_id) values (" \
                                    "(select id from page where url = \x27' || quote(url) || '\x27)," \
                                    "(select id from page where url = \x27" $1 "\x27)" \
                                ");"}''',links))
        end as link_insert_queries

    from parse_links
),
content_insert(content_insert_query) as (
    select
        printf("%s",'update page set content = ' || quote(content) || 'where url = ' || quote(url) || ';')

    from
        parse_content
),
full_insert(insert_queries) as (
    select
        -- determine parseability
        case when (
            coalesce(whitelisted_url.url,'') = ''
            or coalesce(parse_content.content,'') = ''
        ) then printf("%s",'update page set is_retired = 1 where url = ' || quote(whitelisted_url.url) || ';')
        else
            printf("%s",'begin transaction;')
            || content_insert.content_insert_query
            || link_inserts.link_insert_queries
            || printf("%s",'commit;')
        end as insert_queries

    from content_insert,link_inserts,whitelisted_url,parse_content
)
select
    --whitelisted_url.domain,
    --whitelisted_url.url,
    --whitelisted_url.path,
    --whitelisted_url.rank,
    --parse_links.links,
    --link_inserts.link_insert_queries,
    --content_insert.content_insert_query,
    full_insert.insert_queries

from
    --whitelisted_url,
    --parse_links,
    --link_inserts,
    --content_insert,
    full_insert
;
