-- The graph data and algorithm source from the book "Mining of Massive Datasets", P175, http://infolab.stanford.edu/~ullman/mmds/book.pdf
-- This script has been verified the correctness in SQL Server 2017 Linux Version.
m4_divert(KILL)
m4_define([ALPHA],[0.8])
m4_divert(GROW)dnl

begin transaction;
with node_num(num_nodes) as (
    select count(*) as num_nodes from node
)

    INSERT INTO tmp_rank
    SELECT edge.dst, SUM(ALPHA * page_rank.rank / out_degree.degree) + (1 - ALPHA) / (select num_nodes from node_num) as rank
    FROM page_rank
    INNER JOIN edge ON page_rank.id = edge.src
    INNER JOIN out_degree ON page_rank.id = out_degree.id
    GROUP BY edge.dst;

    DELETE FROM page_rank;
    INSERT INTO page_rank
    SELECT * FROM tmp_rank;
    DELETE FROM tmp_rank;
commit;

