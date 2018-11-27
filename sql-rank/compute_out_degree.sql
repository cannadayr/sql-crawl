INSERT INTO out_degree
SELECT page.id, COUNT(link.src) --Count(link.src) instead of Count(*) for count no out-degree link
FROM page LEFT OUTER JOIN link
ON page.id = link.src
GROUP BY page.id;

--WARN: There's no special process for page with out-degree, This may cause wrong result
--      Please to make sure every page in graph has out-degree

