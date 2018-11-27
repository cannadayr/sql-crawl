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

