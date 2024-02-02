set enable_global_stats = true;
---------
---case 1: truncate partition table with index
---------
create table create_columnar_table_106 ( c_smallint smallint null,c_double_precision double precision,c_time_without_time_zone time without time zone null,c_time_with_time_zone time with time zone,c_integer integer default 23423,c_bigint bigint default 923423432,c_decimal decimal(19) default 923423423,c_real real,c_numeric numeric(18,12) null,c_varchar varchar(19),c_char char(57) null,c_timestamp_with_timezone timestamp with time zone,c_char2 char default '0',c_text text null,c_varchar2 varchar2(20),c_timestamp_without_timezone timestamp without time zone,c_date date,c_varchar22 varchar2(11621),c_numeric2 numeric null ) with (orientation = column , compression=no) distribute by hash(c_time_without_time_zone)
partition by range(c_smallint)(
partition create_columnar_table_partition_p5 values less than(4121),
partition create_columnar_table_partition_p6 values less than(maxvalue)) ;

create index create_columnar_index_1_106 on create_columnar_table_106(c_integer,c_numeric,c_text,c_timestamp_with_timezone) local;

alter table create_columnar_table_106 truncate partition create_columnar_table_partition_p6;


insert into create_columnar_table_106 values(32431);

alter table create_columnar_table_106 truncate partition create_columnar_table_partition_p6;
insert into create_columnar_table_106 values(32431);
select * from create_columnar_table_106;
drop table create_columnar_table_106;
