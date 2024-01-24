set enable_global_stats = true;
--unsupport features
---

create table unsupp_parent(c1 int, c2 int) with (orientation = orc) tablespace hdfs_ts ;

create table unsupp_rep_cstore(c1 int, c2 int) with(orientation = column) distribute by replication;

--add contraint
----
alter table unsupp_parent alter column c1 set not null;

--1. Alter table
---
alter table unsupp_parent add column c3 int;
alter table unsupp_parent drop column c3;
alter table unsupp_parent rename column c2 to c3;
alter table unsupp_parent rename to unsupport;
alter table unsupport rename to unsupp_parent;
alter table unsupp_parent alter column c2 set default c2 < c1;
alter table unsupp_parent alter column c1 set null;
alter table unsupp_parent alter column c1 drop not null;

--2. Insert into
---
insert into unsupp_parent values(1, 9);

insert into unsupp_rep_cstore select c1, c2 from unsupp_parent;

--3. Delete
---
delete from unsupp_parent;

delete from unsupp_rep_cstore;

--4. Update
---
update unsupp_parent set c2=0 where c1=1;

update unsupp_rep_cstore set c2=0 where c1=1;

drop table unsupp_parent;

drop table unsupp_rep_cstore;

--5 constraints
--
CREATE TABLE unsupport_check ( a int not null CHECK(a>3.4)) with ( orientation = orc) tablespace hdfs_ts ;
CREATE TABLE unsupport_foreignkey (
    foo_id     regclass     not null,
    name       text        not null,
    rank       integer     not null,
    created_at timestamptz not null,
    foreign key(rank) references pg_attribute(attcacheoff)
) with (orientation = orc) tablespace hdfs_ts  distribute by hash(rank);

--6 index unusable
--
CREATE TABLE unsupport_index_unusable ( a int , b int ) with ( orientation = column );
CREATE INDEX idx_unusable ON unsupport_index_unusable ( b );
ALTER INDEX idx_unusable unusable;
DROP TABLE unsupport_index_unusable;

create table unsupport_index_unusable_p ( a int , b int , c int ) with ( orientation = column )
partition by range ( b )
(
  partition p1 values less than (10),
  partition p2 values less than (20)
);
create index idx_013_001 on unsupport_index_unusable_p (b) local;
alter index idx_013_001 modify partition p1_b_idx unusable;
alter table unsupport_index_unusable_p modify partition p1 unusable local indexes ;
alter table unsupport_index_unusable_p modify partition p2 unusable local indexes ;
DROP TABLE unsupport_index_unusable_p;
