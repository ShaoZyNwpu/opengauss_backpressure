--==========================================================
--==========================================================
\set ECHO all
set current_schema = hw_es_multi_column_stats;
set default_statistics_target=-2;

--========================================================== complex_array_in
select complex_array_in('{"{1,2,3}","{1,2,3}"}', (select t.oid from pg_class t, pg_namespace n where t.relnamespace=n.oid and relname='t3_7' and nspname='hw_es_multi_column_stats'), '1 2');

select complex_array_in('{"{1,   2,3}","{1,2,   3}"}', (select t.oid from pg_class t, pg_namespace n where t.relnamespace=n.oid and relname='t3_7' and nspname='hw_es_multi_column_stats'), '1 2');

select complex_array_in('{"{1,   2,3}","{1,2,   3}"}', (select t.oid from pg_class t, pg_namespace n where t.relnamespace=n.oid and relname='t3_7' and nspname='hw_es_multi_column_stats'), '1 2 3');
