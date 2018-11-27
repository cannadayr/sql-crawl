.load sqlitepipe/sqlitepipe

with whitelisted_url(id,domain,url,path) as (
   select
        --*,
        whitelist.id,
        whitelist.domain,
        page.url,
        page.path
    from whitelist

    left outer join (
        select
            url,
            printf("%s",pipe('uri-parser/uri-parser --protocol --host ' || quote(page.url) || ' | awk ''BEGIN{FS=" "} {printf $1 "://" $2}''')) as domain,
            printf("%s",pipe('uri-parser/uri-parser --path ' || quote(page.url) || ' | tr -d ''\n''')) as path

        from page

        where content is null -- TODO add a last_fetched field and query-by

        and is_retired is not 1

    ) page on page.domain = whitelist.domain

    where page.url is not null

    limit 1
),
disallow_rules(pattern,is_match) as (
    select
        pattern,
        printf("%s",pipe('printf "%s" ' || quote((select path from whitelisted_url)) || ' | awk ''BEGIN{ret=0} /^' || pattern || '/{ret=1} END{printf ret}''')) as is_match
    from rule

    where
        whitelist_id = (select id from whitelisted_url)
        and is_allowed = 0
)
select
    --*, -- enable for debugging
    case when (
        coalesce(url,'') = ''
        or coalesce(content,'') = ''
    ) then printf("%s",'update page set is_retired = 1 where url = ' || quote(url) || ';')
    else
        printf("%s",'begin transaction; update page set content = ' || quote(content) || 'where url = ' || quote(url) || ';')
        || pipe('while IFS= read -r line; do uri-parser/uri-parser  --protocol --host "${line}" | awk ''BEGIN{ret=1} {if(NF==2){ret=0;}} END{exit ret}'' && { uri-parser/uri-parser --defragment "${line}" | awk ''{print "insert into page (url) values (\x27" $1 "\x27); insert into link (src_page_id,dest_page_id) values ((select id from page where url = \x27' || quote(url) || '\x27), (select id from page where url = \x27" $1 "\x27));" }'';}; done',links)
        || printf("%s",'commit;')
    end as insert_queries
from (
    select
        url,
        printf("%s",pipe('tac | sed ''0,/^References/d'' | tac',full_content)) as content, -- can't quote full_content
        printf("%s",pipe('tac | sed ''/^References/q'' | head -n -2 | sed ''s/\s\+[0-9]\+\.\s\(.*\)$/\1/''',full_content)) as links -- can't quote full_content

    from (
        select
            url,
            case when (
                (select count(is_match) from disallow_rules where is_match = "1") >= 1
            ) then printf("%s","") -- just return the empty str and we'll catch it later
            else
                -- the '-nonumbers' options might help w/ full-text search
                -- however it removes the 'Reference' delimiter making separating links & content easier
                pipe('lynx -dump -nostatus -notitle -unique_urls --hiddenlinks=ignore ' || quote(url))
            end as full_content

        from whitelisted_url
    )
)
;
