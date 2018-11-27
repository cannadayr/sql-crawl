CREATE TABLE page(id int PRIMARY KEY);
CREATE TABLE link(src int,dst int, PRIMARY KEY (src, dst));
CREATE TABLE out_degree(id int PRIMARY KEY, degree int);
CREATE TABLE page_rank(id int PRIMARY KEY, rank float);
CREATE TABLE tmp_rank(id int PRIMARY KEY, rank float);

