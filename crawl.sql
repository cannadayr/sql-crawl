.load sqlitepipe/sqlitepipe

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
