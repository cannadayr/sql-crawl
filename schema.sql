create table page (
    id integer primary key,
    url text,
    content text,
    is_retired integer, -- set this to '1' if the content is unparseable
    last_fetched timestamp default current_timestamp,
    unique (url) on conflict ignore
);

--TODO out_degree, page_rank & tmp_rank could probably be fields on the page table
-- the id's directly corresponds to page_id
create table out_degree (
    id integer primary key,
    degree int
);

create table page_rank (
    id integer primary key,
    rank float
);

create table tmp_rank (
    id integer primary key,
    rank float
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

create table rule (
    id integer primary key,
    whitelist_id integer,
    pattern text,
    is_allowed integer,
    unique (whitelist_id,pattern,is_allowed) on conflict ignore
);

