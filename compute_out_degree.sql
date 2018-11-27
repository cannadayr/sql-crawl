INSERT INTO OutDegree
SELECT Node.id, COUNT(Edge.src) --Count(Edge.src) instead of Count(*) for count no out-degree edge
FROM Node LEFT OUTER JOIN Edge
ON Node.id = Edge.src
GROUP BY Node.id;

--WARN: There's no special process for node with out-degree, This may cause wrong result
--      Please to make sure every node in graph has out-degree

