-- The graph data and algorithm source from the book "Mining of Massive Datasets", P175, http://infolab.stanford.edu/~ullman/mmds/book.pdf
-- This script has been verified the correctness in SQL Server 2017 Linux Version.
m4_divert(KILL)
m4_define([ALPHA],[0.8])
m4_divert(GROW)dnl

DECLARE @Node_Num int;
SELECT @Node_Num = COUNT(*) FROM Node;

--PageRank Init Value
INSERT INTO PageRank
SELECT Node.id, rank = (1 - ALPHA) / @Node_Num
FROM Node INNER JOIN OutDegree
ON Node.id = OutDegree.id

/*
--For Debugging
SELECT * FROM Node;
SELECT * FROM Edge;
SELECT * FROM OutDegree;
SELECT * FROM PageRank;
SELECT * FROM TmpRank;
*/

DECLARE @Iteration int = 0;

WHILE @Iteration < 50
BEGIN
--Iteration Style
    SET @Iteration = @Iteration + 1

    INSERT INTO TmpRank
    SELECT Edge.dst, rank = SUM(ALPHA * PageRank.rank / OutDegree.degree) + (1 - ALPHA) / @Node_Num
    FROM PageRank
    INNER JOIN Edge ON PageRank.id = Edge.src
    INNER JOIN OutDegree ON PageRank.id = OutDegree.id
    GROUP BY Edge.dst

    DELETE FROM PageRank;
    INSERT INTO PageRank
    SELECT * FROM TmpRank;
    DELETE FROM TmpRank;
END

SELECT * FROM PageRank;
