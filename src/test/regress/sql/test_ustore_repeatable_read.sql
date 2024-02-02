set default_transaction_isolation = 'repeatable read';
create table z1 (c1 int) with (storage_type=USTORE);

insert into z1 values (1);

\parallel on 2

declare
	cnt int;
begin 
    select c1 into cnt from z1; -- generate RR snapshot
    perform pg_sleep(3);        -- allow all updates to finish first
    select c1 into cnt from z1; -- should reuse the snapshot to fetch the oldest value
    if cnt != 1 then
        raise notice 'ERROR: RR expect c1 = %, but %', 1, cnt;
    end if;
end;
/

begin
    perform pg_sleep(.5);
    update z1 set c1 = c1 + 1;
end;
/

update z1 set c1 = c1 + 1;
update z1 set c1 = c1 + 1;

\parallel off

select * from z1; -- should be 4

drop table z1;
reset default_transaction_isolation;
