.load sqlitepipe/sqlitepipe

with whitelisted_urls as (
    select
        url
    from whitelist

    left outer join (
        select
            url,
            printf("%s",pipe('sed ''s/^.*:\/\///'' | sed ''s/\([^\/]*\)\/.*/\1/'' | awk -F"." ''{printf $(NF-1) "." $NF}''',page.url)) as domain

        from page

        where content is null -- TODO add a last_fetched field and query-by

    ) page on page.domain = whitelist.domain

    limit 1
)
select
    printf("%s",'update page set content = ' || quote(content) || ' where url = ' || quote(url) || ';')
    || pipe('awk ''{print "insert into page (url) values (\x27" $1 "\x27);"}''',links)
    || pipe('awk ''{print "insert into link (src_page_id,dest_page_id) values ((select id from page where url = \x27' || quote(url) || '\x27),(select id from page where url = \x27" $1 "\x27));"}''',links)

from (
    select
        url,
        printf("%s",pipe('tac | sed ''0,/^References/d'' | tac',full_content)) as content,
        printf("%s",pipe('tac | sed ''/^References/q'' | head -n -2 | sed ''s/\s\+[0-9]\+\.\s\([^\"]*\)$/\1/''',full_content)) as links

    from (
        select
            url,
            -- the '-nonumbers' options might help w/ full-text search
            -- however it removes the 'Reference' delimiter making separating links & content easier
            pipe('lynx -dump -nostatus -notitle -unique_urls ' || quote(url)) as full_content

        from whitelisted_urls
    )
)
;
