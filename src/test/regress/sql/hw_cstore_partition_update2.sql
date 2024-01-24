--18--------------------------------------------------------------------
--not null constraint
create table cstore_update2_table
(
	c1 int ,
	c2 int not null,
	c3 int
)with(orientation = column)
partition by range (c1,c2)
(
	partition cstore_update2_table_p0 values less than (50,0),
	partition cstore_update2_table_p1 values less than (100,0),
	partition cstore_update2_table_p2 values less than (150,0)
)enable row movement
;

create index on cstore_update2_table(c1,c2)local;

insert into cstore_update2_table values(99,null);
--error
insert into cstore_update2_table values(99,0);

update cstore_update2_table set c2 = null where c2  = 0;
--error 
drop table cstore_update2_table;

--19--------------------------------------------------------------------
create table cstore_update2_table
(
	c1 int,
	c2 int
)with(orientation = column)
partition by range (c2)
(
	partition cstore_update2_table_p0 values less than (10),
	partition cstore_update2_table_p1 values less than (20),
	partition cstore_update2_table_p2 values less than (30)
)enable row movement;

create index on cstore_update2_table(c1,c2)local;
insert into cstore_update2_table values (0, 5);
select * from cstore_update2_table partition (cstore_update2_table_p0);
update cstore_update2_table set c2=15 where c2=5;
select * from cstore_update2_table partition (cstore_update2_table_p0);
select * from cstore_update2_table partition (cstore_update2_table_p1);

drop table cstore_update2_table;


CREATE TABLE hw_partition_update_tt(c_id int NOT NULL,c_first varchar(16) NOT NULL,c_data varchar(500))
with(orientation = column)
partition by range(c_id)
(
	partition hw_partition_update_tt_p1 values less than (11),
	partition hw_partition_update_tt_p2 values less than (31)
) ENABLE ROW MOVEMENT;
insert into hw_partition_update_tt values(1,'aaaaaaaaaaaaaaaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
insert into hw_partition_update_tt values(3,'aaaaaaaaaaaaaaaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
insert into hw_partition_update_tt values(5,'aaaaaaaaaaaaaaaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
insert into hw_partition_update_tt values(7,'aaaaaaaaaaaaaaaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
insert into hw_partition_update_tt values(10,'aaaaaaaaaaaaaaaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
insert into hw_partition_update_tt values(15,'aaaaaaaaaaaaaaaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
insert into hw_partition_update_tt values(18,'aaaaaaaaaaaaaaaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
insert into hw_partition_update_tt values(24,'aaaaaaaaaaaaaaaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
insert into hw_partition_update_tt values(28,'aaaaaaaaaaaaaaaa','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');

START TRANSACTION ISOLATION LEVEL READ COMMITTED;
UPDATE hw_partition_update_tt SET (c_first,c_data) = ('aaaaa','aaaaa') where c_id > 10 and c_id <= 20;
SELECT distinct c_first,c_data,count(c_first) FROM hw_partition_update_tt where c_id > 10 and c_id <= 20 GROUP BY c_first,c_data order by c_first;
-- /* skip the case for pgxc */
--SELECT RELNAME FROM PG_PARTITION WHERE PARENTID IN (SELECT OID FROM PG_CLASS WHERE RELNAME IN ('hw_partition_update_tt')) order by RELNAME;

--PRAGMA AUTONOMOUS_TRANSACTION;
--UPDATE hw_partition_update_tt SET (c_id,c_first,c_data) = (c_id + 10000,'aaaaa','aaaaa') where c_id > 20;
--SELECT RELNAME FROM PG_PARTITION WHERE PARENTID IN (SELECT OID FROM PG_CLASS WHERE RELNAME IN ('hw_partition_update_tt')) order by RELNAME;
--SELECT distinct c_first,c_data,count(c_first) FROM hw_partition_update_tt where c_id > 10000 GROUP BY c_first,c_data order by c_first;
--ROLLBACK;

SELECT distinct c_first,c_data,count(c_first) FROM hw_partition_update_tt where c_id > 10 and c_id <= 20 GROUP BY c_first,c_data order by c_first;
SELECT count(c_first) FROM hw_partition_update_tt;
COMMIT;

DROP TABLE hw_partition_update_tt;


create table test_update_rowmovement (a int, b int)
with(orientation = column)
partition by range (b)
(
	partition test_update_rowmovement_p1 values less than (10)
) enable row movement;

insert into test_update_rowmovement values (-1, 5);

update test_update_rowmovement set b=16;

drop table test_update_rowmovement;

----
-- partial cluster key
----
create table row_update_table (c1 int, c2 int, c3 int)  ;
insert into row_update_table values(1, generate_series(1, 500), generate_series(1, 500));
create table cstore_part_update_table (c1 int, c2 int, c3 int, partial cluster key(c3))
with(orientation = column)
 
partition by range (c2)
(
	partition p1  values less than (100),
	partition p2  values less than (200),
	partition p3  values less than (300),
	partition p4  values less than (400),
	partition p5  values less than (500),
	partition p6  values less than (maxvalue)
);
insert into cstore_part_update_table select * from row_update_table;
alter table cstore_part_update_table add column c4 int;
update cstore_part_update_table set c4 = c3;
drop table cstore_part_update_table;
drop table row_update_table;

