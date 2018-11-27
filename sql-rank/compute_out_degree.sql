INSERT INTO out_degree
SELECT page.id, COUNT(link.src_page_id) --Count(link.src_page_id) instead of Count(*) for count no out-degree link
FROM page LEFT OUTER JOIN link
ON page.id = link.src_page_id
GROUP BY page.id;

--WARN: There's no special process for page with out-degree, This may cause wrong result
--      Please to make sure every page in graph has out-degree

