show client_encoding;
SET client_encoding TO UTF8;
CREATE TABLE order_cn_table(cn VARCHAR(80), sort INTEGER);
INSERT INTO order_cn_table VALUES('华',28);
INSERT INTO order_cn_table VALUES('怎',27);
INSERT INTO order_cn_table VALUES('贼',26);
INSERT INTO order_cn_table VALUES('以',25);
INSERT INTO order_cn_table VALUES('希',24);
INSERT INTO order_cn_table VALUES('我',23);
INSERT INTO order_cn_table VALUES('提',22);
INSERT INTO order_cn_table VALUES('疼',21);
INSERT INTO order_cn_table VALUES('思',20);
INSERT INTO order_cn_table VALUES('人',19);
INSERT INTO order_cn_table VALUES('其',18);
INSERT INTO order_cn_table VALUES('皮',17);
INSERT INTO order_cn_table VALUES('哦',16);
INSERT INTO order_cn_table VALUES('你',15);
INSERT INTO order_cn_table VALUES('米',14);
INSERT INTO order_cn_table VALUES('绿',13);
INSERT INTO order_cn_table VALUES('路',12);
INSERT INTO order_cn_table VALUES('力',11);
INSERT INTO order_cn_table VALUES('看',10);
INSERT INTO order_cn_table VALUES('及',9);
INSERT INTO order_cn_table VALUES('好',8);
INSERT INTO order_cn_table VALUES('个',7);
INSERT INTO order_cn_table VALUES('飞',6);
INSERT INTO order_cn_table VALUES('额',5);
INSERT INTO order_cn_table VALUES('第',4);
INSERT INTO order_cn_table VALUES('次',3);
INSERT INTO order_cn_table VALUES('比',2);
INSERT INTO order_cn_table VALUES('爱',1);
SELECT * FROM order_cn_table ORDER BY NLSSORT(cn, 'NLS_SORT = SCHINESE_PINYIN_M');
SELECT * FROM order_cn_table ORDER BY NLSSORT(cn, 'NLS_SORT = generic_m_ci');
SELECT * FROM order_cn_table ORDER BY NLSSORT(cn, 'NLS_SORT = SCHINESE');
SELECT * FROM order_cn_table ORDER BY NLSSORT(cn, 'nls_sort = schinese_pinyin_m') desc nulls first;
SELECT * FROM order_cn_table t ORDER BY NLSSORT(t.cn, 'nls_sort = schinese_pinyin_m') asc nulls last;
SELECT * FROM order_cn_table ORDER BY NLSSORT(decode(cn,'0','0',cn), 'nls_sort = schinese_pinyin_m') asc nulls last;
DROP TABLE order_cn_table;
create table order_cn_table(cn varchar(10));
insert into order_cn_table values('Aa');
insert into order_cn_table values('AB');
SELECT * FROM order_cn_table ORDER BY NLSSORT(cn, 'nls_sort = SCHINESE_PINYIN_M');
explain (verbose, costs off) SELECT * FROM order_cn_table ORDER BY NLSSORT(cn, 'nls_sort = SCHINESE_PINYIN_M');
DROP TABLE order_cn_table;
