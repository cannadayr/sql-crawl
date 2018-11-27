m4_divert(KILL)
m4_define([ALPHA],[0.8])
m4_divert(GROW)dnl

--page_rank Init Value
INSERT INTO page_rank (id, rank)
    SELECT
        page.id,
        (1 - ALPHA) / (select count(*) from page) as rank
    FROM page INNER JOIN out_degree
    ON page.id = out_degree.id
;
