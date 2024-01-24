--test for expression deduce by inequality

--1. inner join
--	1.1. where

--	1.2. join on

--	1.3. hybrid

--	1.4. subquery

--2. left join
--	2.1. where
--	2.2. join on
--	2.3. hybrid

--3. full join
--	3.1. where
--	3.2. join on
--	3.3. hybrid
--0. create table
create table deduce_t1 (c1 int,c2 int);
create table deduce_t2 (c1 int,c2 int);
create table deduce_t3 (c1 int,c2 int);

insert into deduce_t1 values(11,11);
insert into deduce_t2 values(11,11),(22,22);
insert into deduce_t3 values(11,11),(22,22),(33,33),(44,44);

--1.1 where 
explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1,deduce_t2 t2 where t1.c1=t2.c1 and t1.c1>10;

select * from deduce_t1 t1,deduce_t2 t2 where t1.c1=t2.c1 and t1.c1>10;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1,deduce_t2 t2 where t1.c1=t2.c1 and 10<t1.c1;

select * from deduce_t1 t1,deduce_t2 t2 where t1.c1=t2.c1 and 10<t1.c1;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1,deduce_t2 t2 where t1.c1=t2.c1 and t1.c1>10 and t2.c1<20;

select * from deduce_t1 t1,deduce_t2 t2 where t1.c1=t2.c1 and t1.c1>10 and t2.c1<20;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1,deduce_t2 t2 where t1.c1=t2.c1 and t1.c1>10+20;

select * from deduce_t1 t1,deduce_t2 t2 where t1.c1=t2.c1 and t1.c1>10+20;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1,deduce_t2 t2 where t1.c1=t2.c1 and t1.c1>10 or t2.c1<20;

select * from deduce_t1 t1,deduce_t2 t2 where t1.c1=t2.c1 and t1.c1>10 or t2.c1<20;

--1.2 join on
explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 inner join deduce_t2 t2 on (t1.c1=t2.c1 and t1.c1>10);

select * from deduce_t1 t1 inner join deduce_t2 t2 on (t1.c1=t2.c1 and t1.c1>10);

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 inner join deduce_t2 t2 on (t1.c1=t2.c1 and 10<t1.c1);

select * from deduce_t1 t1 inner join deduce_t2 t2 on (t1.c1=t2.c1 and 10<t1.c1);

--1.3 hybrid
explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 inner join deduce_t2 t2 on (t1.c1=t2.c1) where t1.c1>10;

select * from deduce_t1 t1 inner join deduce_t2 t2 on (t1.c1=t2.c1) where t1.c1>10;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 inner join deduce_t2 t2 on (t1.c1>10) where t1.c1=t2.c1;

select * from deduce_t1 t1 inner join deduce_t2 t2 on (t1.c1>10) where t1.c1=t2.c1;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 inner join deduce_t2 t2 on (t1.c1>10) where t1.c1=t2.c1 and t2.c1>11;

select * from deduce_t1 t1 inner join deduce_t2 t2 on (t1.c1>10) where t1.c1=t2.c1 and t2.c1>11;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 inner join deduce_t2 t2 on (t1.c1>10) where t1.c1=t2.c1 and t2.c2=10;

--1.4 subquery
explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1, deduce_t2 t2, (select t3.c1,t3.c2 from deduce_t3 t3 left join deduce_t1 t1 on (t3.c1=t1.c1)) as tt(c1,c2) 
where t1.c1=t2.c1 and t2.c1>10 and tt.c2>t1.c1;

--2 left join
--2.1 where 
explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 left join deduce_t2 t2 on true where t1.c1=t2.c1 and t1.c1>10;

select * from deduce_t1 t1 left join deduce_t2 t2 on true where t1.c1=t2.c1 and t1.c1>10;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 left join deduce_t2 t2 on true where t1.c1=t2.c1 and t2.c1>10;

select * from deduce_t1 t1 left join deduce_t2 t2 on true where t1.c1=t2.c1 and t2.c1>10;

--2.2 join on
explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 left join deduce_t2 t2 on (t1.c1=t2.c1 and t1.c1>10);

select * from deduce_t1 t1 left join deduce_t2 t2 on (t1.c1=t2.c1 and t1.c1>10);

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 left join deduce_t2 t2 on (t1.c1=t2.c1 and t2.c1>10);

select * from deduce_t1 t1 left join deduce_t2 t2 on (t1.c1=t2.c1 and t2.c1>10);

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 left join deduce_t2 t2 on (t1.c1=t2.c1 and 10<t1.c1);

select * from deduce_t1 t1 left join deduce_t2 t2 on (t1.c1=t2.c1 and 10<t1.c1);

--2.3 hybrid
explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 left join deduce_t2 t2 on (t1.c1=t2.c1) where t1.c1>10;

select * from deduce_t1 t1 left join deduce_t2 t2 on (t1.c1=t2.c1) where t1.c1>10;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 left join deduce_t2 t2 on (t1.c1=t2.c1) where t2.c1>10;

select * from deduce_t1 t1 left join deduce_t2 t2 on (t1.c1=t2.c1) where t2.c1>10;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 left join deduce_t2 t2 on (t1.c1>10) where t1.c1=t2.c1;

select * from deduce_t1 t1 left join deduce_t2 t2 on (t1.c1>10) where t1.c1=t2.c1;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 left join deduce_t2 t2 on (t2.c1>10) where t1.c1=t2.c1;

select * from deduce_t1 t1 left join deduce_t2 t2 on (t2.c1>10) where t1.c1=t2.c1;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 left join deduce_t2 t2 on (t1.c1>10) where t1.c1=t2.c1 and t2.c1>11;

select * from deduce_t1 t1 left join deduce_t2 t2 on (t1.c1>10) where t1.c1=t2.c1 and t2.c1>11;

--3 full join
--3.1 where 
explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 full join deduce_t2 t2 on true where t1.c1=t2.c1 and t1.c1>10;

select * from deduce_t1 t1 full join deduce_t2 t2 on true where t1.c1=t2.c1 and t1.c1>10;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 full join deduce_t2 t2 on true where t1.c1=t2.c1 and t2.c1>10;

select * from deduce_t1 t1 full join deduce_t2 t2 on true where t1.c1=t2.c1 and t2.c1>10;

--3.2 join on
explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 full join deduce_t2 t2 on (t1.c1=t2.c1 and t1.c1>10);

select * from deduce_t1 t1 full join deduce_t2 t2 on (t1.c1=t2.c1 and t1.c1>10) order by 1, 2, 3, 4;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 full join deduce_t2 t2 on (t1.c1=t2.c1 and t2.c1>10);

select * from deduce_t1 t1 full join deduce_t2 t2 on (t1.c1=t2.c1 and t2.c1>10) order by 1, 2, 3, 4;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 full join deduce_t2 t2 on (t1.c1=t2.c1 and 10<t1.c1);

select * from deduce_t1 t1 full join deduce_t2 t2 on (t1.c1=t2.c1 and 10<t1.c1) order by 1, 2, 3, 4;

--3.3 hybrid
explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 full join deduce_t2 t2 on (t1.c1=t2.c1) where t1.c1>10;

select * from deduce_t1 t1 full join deduce_t2 t2 on (t1.c1=t2.c1) where t1.c1>10;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 full join deduce_t2 t2 on (t1.c1=t2.c1) where t2.c1>10;

select * from deduce_t1 t1 full join deduce_t2 t2 on (t1.c1=t2.c1) where t2.c1>10 order by 1;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 full join deduce_t2 t2 on (t1.c1>10) where t1.c1=t2.c1;

select * from deduce_t1 t1 full join deduce_t2 t2 on (t1.c1>10) where t1.c1=t2.c1;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 full join deduce_t2 t2 on (t2.c1>10) where t1.c1=t2.c1;

select * from deduce_t1 t1 full join deduce_t2 t2 on (t2.c1>10) where t1.c1=t2.c1;

explain (ANALYZE false,VERBOSE false, COSTS false,BUFFERS false,TIMING false)
select * from deduce_t1 t1 full join deduce_t2 t2 on (t1.c1>10) where t1.c1=t2.c1 and t2.c1>11;

select * from deduce_t1 t1 full join deduce_t2 t2 on (t1.c1>10) where t1.c1=t2.c1 and t2.c1>11;

drop table deduce_t1;
drop table deduce_t2;
drop table deduce_t3;

