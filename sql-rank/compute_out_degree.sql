INSERT INTO out_degree
SELECT page.id, COUNT(edge.src) --Count(edge.src) instead of Count(*) for count no out-degree edge
FROM page LEFT OUTER JOIN edge
ON page.id = edge.src
GROUP BY page.id;

--WARN: There's no special process for page with out-degree, This may cause wrong result
--      Please to make sure every page in graph has out-degree

