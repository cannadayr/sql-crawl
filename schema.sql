create table page (
    id integer primary key,
    url text,
    content text,
    unique (url) on conflict ignore
);

create table link (
    id integer primary key,
    src_page_id integer,
    dest_page_id integer,
    unique (src_page_id, dest_page_id) on conflict ignore
);

create table whitelist (
    id integer primary key,
    domain text,
    unique (domain) on conflict ignore
);

