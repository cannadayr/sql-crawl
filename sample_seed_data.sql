-- WARNING: Use this ONLY on domains you control!

-- expects to end w/ a '/'
insert into page (url) values ("https://www.example.com/");

-- no slash ending for whitelist
insert into whitelist (domain) values ("example.com");
