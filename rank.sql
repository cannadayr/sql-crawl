-- The graph data and algorithm source from the book "Mining of Massive Datasets", P175, http://infolab.stanford.edu/~ullman/mmds/book.pdf
-- This script has been verified the correctness in SQL Server 2017 Linux Version.

--init basic tables
INSERT INTO Node VALUES (0);
INSERT INTO Node VALUES (1);
INSERT INTO Node VALUES (2);
INSERT INTO Node VALUES (3);

INSERT INTO Edge VALUES (0, 1);
INSERT INTO Edge VALUES (0, 2);
INSERT INTO Edge VALUES (0, 3);
INSERT INTO Edge VALUES (1, 0);
INSERT INTO Edge VALUES (1, 3);
INSERT INTO Edge VALUES (2, 2);
INSERT INTO Edge VALUES (3, 1);
INSERT INTO Edge VALUES (3, 2);

--compute out-degree
INSERT INTO OutDegree
SELECT Node.id, COUNT(Edge.src) --Count(Edge.src) instead of Count(*) for count no out-degree edge
FROM Node LEFT OUTER JOIN Edge
ON Node.id = Edge.src
GROUP BY Node.id;

--WARN: There's no special process for node with out-degree, This may cause wrong result
--      Please to make sure every node in graph has out-degree

DECLARE @ALPHA float = 0.8;
DECLARE @Node_Num int;
SELECT @Node_Num = COUNT(*) FROM Node;

--PageRank Init Value
INSERT INTO PageRank
SELECT Node.id, rank = (1 - @ALPHA) / @Node_Num
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
    SELECT Edge.dst, rank = SUM(@ALPHA * PageRank.rank / OutDegree.degree) + (1 - @ALPHA) / @Node_Num
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
