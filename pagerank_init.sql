m4_divert(KILL)
m4_define([ALPHA],[0.8])
m4_divert(GROW)dnl

--page_rank Init Value
INSERT INTO page_rank (id, rank)
    SELECT
        node.id,
        (1 - ALPHA) / (select count(*) from node) as rank
    FROM node INNER JOIN out_degree
    ON node.id = out_degree.id
;
