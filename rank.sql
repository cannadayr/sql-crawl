-- The graph data and algorithm source from the book "Mining of Massive Datasets", P175, http://infolab.stanford.edu/~ullman/mmds/book.pdf
-- This script has been verified the correctness in SQL Server 2017 Linux Version.
m4_divert(KILL)
m4_define([ALPHA],[0.8])
m4_divert(GROW)dnl

begin transaction;
with node_num(num_nodes) as (
    select count(*) as num_nodes from Node
)

    INSERT INTO TmpRank
    SELECT Edge.dst, rank = SUM(ALPHA * PageRank.rank / OutDegree.degree) + (1 - ALPHA) / (select num_nodes from node_num)
    FROM PageRank
    INNER JOIN Edge ON PageRank.id = Edge.src
    INNER JOIN OutDegree ON PageRank.id = OutDegree.id
    GROUP BY Edge.dst;

    DELETE FROM PageRank;
    INSERT INTO PageRank
    SELECT * FROM TmpRank;
    DELETE FROM TmpRank;
commit;

