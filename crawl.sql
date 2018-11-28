.load sqlitepipe/sqlitepipe

/*
-- Use this for manually testing a url!
with whitelisted_url(id,domain,url,path,rank) as (
    select
        1,
        'https://www.example.com',
        'https://www.example.com/?var=val',
        '/?var=val',
        0.00015
),
*/
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
        printf("%s",pipe('tac | sed ''/^References/q'' | head -n -2 | sed ''s/\s\+[0-9]\+\.\s//''',full_content)) as links

    from fetch_content
),
-- https://stackoverflow.com/questions/34659643/split-a-string-into-rows-using-pure-sqlite
-- https://stackoverflow.com/users/11654/cl
-- creates a tmp tbl w/ the parsed links
split_links(word,str,hasnewline) as (
    values('',(select links from parse_links),1)
    union all
    select
        substr(str, 0,
            case when instr(str, x'0a')
            then instr(str, x'0a')
            else length(str)+1 end),
        ltrim(substr(str, instr(str, x'0a')), x'0a'),
        instr(str, x'0a')
        from split_links
        where hasnewline
),
link_tbl(link) as (
    select trim(word) FROM split_links WHERE word!=''
),
defragment_links(url) as (
    select
        -- get the distinct, defragmented urls
        distinct(printf("%s",pipe('xargs uri-parser/uri-parser --defragment | tr -d ''\n''',link))) as url

    from link_tbl
),
-- validates that we have a protocol and a host (avoid javascript:void(0) for example)
validate_links(url) as (
    select
        case when (
            pipe('xargs uri-parser/uri-parser  --protocol --host \
                    | awk ''{if(NF==2){printf "1"}}''',url)
        ) then url
        end as url

    from defragment_links
),
-- this does not check that this inserted link is allowed to be crawled
-- only creates a new record for it
link_inserts(link_insert_queries) as (
    select
        printf("%s",x'0a' || 'insert into page (url) values (' || quote(url) || ');')
        || printf("%s",x'0a' || 'insert into link (src_page_id,dest_page_id) values ('
                                || '(select id from page where url = ' || (select quote(url) from whitelisted_url) || '),'
                                || '(select id from page where url = ' || quote(url) || '));') as link_insert_queries

    from validate_links

    where coalesce(url,'')  <> ''
),
content_insert(content_insert_query) as (
    select
        printf("%s",'update page set content = ' || quote(content) || ' where url = ' || quote(url) || ';')

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
            printf("%s",x'0a' || 'begin transaction;')
            || x'0a' || content_insert.content_insert_query
            || group_concat(link_insert_queries,'')
            || printf("%s",x'0a' || 'commit;')
        end as insert_queries

    from content_insert,whitelisted_url,parse_content,link_inserts
)
select
    --whitelisted_url.*,
    --disallow_rules.*,
    --fetch_content.*,
    --parse_content.*
    --parse_links.*
    --link_tbl.*,
    --validate_links.*,
    --link_inserts.*,
    --content_insert.*,
    -- to enable we only want to return the full_insert queries!
    full_insert.insert_queries

from
    --whitelisted_url,
    --disallow_rules,
    --fetch_content,
    --parse_content,
    --parse_links,
    --link_tbl,
    --validate_links,
    --link_inserts,
    --content_insert,
    full_insert

--limit 10
;
