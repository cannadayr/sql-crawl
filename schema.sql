CREATE TABLE Node(id int PRIMARY KEY);
CREATE TABLE Edge(src int,dst int, PRIMARY KEY (src, dst));
CREATE TABLE OutDegree(id int PRIMARY KEY, degree int);
CREATE TABLE PageRank(id int PRIMARY KEY, rank float);
CREATE TABLE TmpRank(id int PRIMARY KEY, rank float);

