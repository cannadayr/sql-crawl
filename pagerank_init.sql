m4_divert(KILL)
m4_define([ALPHA],[0.8])
m4_divert(GROW)dnl

--PageRank Init Value
INSERT INTO PageRank (id, rank)
    SELECT
        Node.id,
        (1 - ALPHA) / (select count(*) from Node) as rank
    FROM Node INNER JOIN OutDegree
    ON Node.id = OutDegree.id

