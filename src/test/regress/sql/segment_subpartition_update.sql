--prepare
DROP SCHEMA segment_subpartition_update CASCADE;
CREATE SCHEMA segment_subpartition_update;
SET CURRENT_SCHEMA TO segment_subpartition_update;

--update
CREATE TABLE range_list
(
    month_code VARCHAR2 ( 30 ) NOT NULL ,
    dept_code  VARCHAR2 ( 30 ) NOT NULL ,
    user_no    VARCHAR2 ( 30 ) NOT NULL ,
    sales_amt  int
) WITH (SEGMENT=ON)
PARTITION BY RANGE (month_code) SUBPARTITION BY LIST (dept_code)
(
  PARTITION p_201901 VALUES LESS THAN( '201903' )
  (
    SUBPARTITION p_201901_a values ('1'),
    SUBPARTITION p_201901_b values ('2')
  ),
  PARTITION p_201902 VALUES LESS THAN( '201910' )
  (
    SUBPARTITION p_201902_a values ('1'),
    SUBPARTITION p_201902_b values ('2')
  )
)DISABLE ROW MOVEMENT;

insert into range_list values('201902', '1', '1', 1);
insert into range_list values('201902', '2', '1', 1);
insert into range_list values('201902', '1', '1', 1);
insert into range_list values('201903', '2', '1', 1);
insert into range_list values('201903', '1', '1', 1);
insert into range_list values('201903', '2', '1', 1);

select * from range_list order by 1, 2, 3, 4;

--error
update range_list set month_code = '201903';
--error
update range_list set dept_code = '2';

update range_list set user_no = '2';
select * from range_list order by 1, 2, 3, 4;

-- test for upsert and merge into, both should report error
insert into range_list values('201902', '1', '1', 1) ON DUPLICATE KEY UPDATE sales_amt=1;

CREATE TABLE temp_table
(
    month_code VARCHAR2 ( 30 ) NOT NULL ,
    dept_code  VARCHAR2 ( 30 ) NOT NULL ,
    user_no    VARCHAR2 ( 30 ) NOT NULL ,
    sales_amt  int
) WITH (SEGMENT=ON);
insert into temp_table values('201802', '1', '1', 1), ('201901', '2', '1', 1), ('201702', '1', '1', 1);
MERGE INTO range_list t1
USING temp_table t2
ON (t1.dept_code = t2.dept_code)
WHEN MATCHED THEN
  UPDATE SET t1.month_code = t2.month_code WHERE t1.dept_code > 1
WHEN NOT MATCHED THEN
  INSERT VALUES (t2.month_code, t2.dept_code, t2.user_no, t2.sales_amt) WHERE t2.sales_amt = 1;

drop table temp_table;
drop table range_list;

CREATE TABLE range_list
(
    month_code VARCHAR2 ( 30 ) NOT NULL ,
    dept_code  VARCHAR2 ( 30 ) NOT NULL ,
    user_no    VARCHAR2 ( 30 ) NOT NULL ,
    sales_amt  int
) WITH (SEGMENT=ON)
PARTITION BY RANGE (month_code) SUBPARTITION BY LIST (dept_code)
(
  PARTITION p_201901 VALUES LESS THAN( '201903' )
  (
    SUBPARTITION p_201901_a values ('1'),
    SUBPARTITION p_201901_b values ('2')
  ),
  PARTITION p_201902 VALUES LESS THAN( '201910' )
  (
    SUBPARTITION p_201902_a values ('1'),
    SUBPARTITION p_201902_b values ('2')
  )
)ENABLE ROW MOVEMENT;

insert into range_list values('201902', '1', '1', 1);
insert into range_list values('201902', '2', '1', 1);
insert into range_list values('201902', '1', '1', 1);
insert into range_list values('201903', '2', '1', 1);
insert into range_list values('201903', '1', '1', 1);
insert into range_list values('201903', '2', '1', 1);

select * from range_list order by 1, 2, 3, 4;

select * from range_list subpartition (p_201901_a) order by 1, 2, 3, 4;
select * from range_list subpartition (p_201901_b) order by 1, 2, 3, 4;
update range_list set dept_code = '2' where month_code = '201902';
select * from range_list subpartition (p_201901_a) order by 1, 2, 3, 4;
select * from range_list subpartition (p_201901_b) order by 1, 2, 3, 4;

select * from range_list partition (p_201901) order by 1, 2, 3, 4;
select * from range_list partition (p_201902) order by 1, 2, 3, 4;
update range_list set month_code = '201903' where month_code = '201902';
select * from range_list partition (p_201901) order by 1, 2, 3, 4;
select * from range_list partition (p_201902) order by 1, 2, 3, 4;

drop table range_list;

-- FOREIGN KEY
drop table tb_02;
CREATE TABLE tb_02
(
    col_1 int PRIMARY KEY,
    col_2 int ,
    col_3 VARCHAR2 ( 30 ) ,
    col_4 int
) WITH (SEGMENT=ON);

drop table range_range_02 cascade;
CREATE TABLE range_range_02
(
    col_1 int ,
    col_2 int ,
    col_3 VARCHAR2 ( 30 ) ,
    col_4 int ,
FOREIGN KEY(col_1) REFERENCES tb_02(col_1)
) WITH (SEGMENT=ON)
PARTITION BY RANGE (col_1) SUBPARTITION BY RANGE (col_2)
(
  PARTITION p_range_1 VALUES LESS THAN( 10 )
  (
    SUBPARTITION p_range_1_1 VALUES LESS THAN( 50 ),
    SUBPARTITION p_range_1_2 VALUES LESS THAN( MAXVALUE )
  ),
  PARTITION p_range_2 VALUES LESS THAN( 80 )
  (
    SUBPARTITION p_range_2_1 VALUES LESS THAN( 50 ),
    SUBPARTITION p_range_2_2 VALUES LESS THAN( MAXVALUE )
  )
);

insert into tb_02 values(0,0,0,0);
insert into range_range_02 values(0,0,0,0);

update tb_02 set col_1=8 where col_2=0;
drop table range_range_02 cascade;
drop table tb_02;
DROP SCHEMA segment_subpartition_update CASCADE;
RESET CURRENT_SCHEMA;
