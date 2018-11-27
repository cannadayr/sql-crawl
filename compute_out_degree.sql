INSERT INTO out_degree
SELECT node.id, COUNT(edge.src) --Count(edge.src) instead of Count(*) for count no out-degree edge
FROM node LEFT OUTER JOIN edge
ON node.id = edge.src
GROUP BY node.id;

--WARN: There's no special process for node with out-degree, This may cause wrong result
--      Please to make sure every node in graph has out-degree

