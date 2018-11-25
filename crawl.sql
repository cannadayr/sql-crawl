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
    url
from whitelist

left outer join (
    select
        url,
        printf("%s",pipe('printf ' || page.url || '| sed ''s/^.*:\/\///'' | awk -F"." ''{printf $(NF-1) "." $NF}''')) as domain

    from page
) page on page.domain = whitelist.domain
;
