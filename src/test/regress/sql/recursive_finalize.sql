set current_schema=rq_cstore;
DROP TABLE IF EXISTS a_rep;
DROP TABLE IF EXISTS b_rep;
DROP TABLE IF EXISTS a;
DROP TABLE IF EXISTS b;
DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS t2;
DROP TABLE IF EXISTS chinamap;
DROP TABLE IF EXISTS chinamap2;
DROP TABLE IF EXISTS chinamap3;
DROP TABLE IF EXISTS chinamap4;
DROP TABLE IF EXISTS area;
reset current_schema;
drop schema rq_cstore cascade;

DROP TABLE IF EXISTS test_rec;
DROP TABLE IF EXISTS test_rec_1;


set current_schema= gcms;
DROP TABLE IF EXISTS gcm_mag_area_h;
DROP TABLE IF EXISTS gcc_mag_district_h;
reset current_schema;
drop schema gcms cascade;

set current_schema=public;
DROP TABLE IF EXISTS a_rep;
DROP TABLE IF EXISTS b_rep;
DROP TABLE IF EXISTS a;
DROP TABLE IF EXISTS b;
DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS t2;
DROP TABLE IF EXISTS chinamap;
DROP TABLE IF EXISTS chinamap2;
DROP TABLE IF EXISTS chinamap3;
DROP TABLE IF EXISTS chinamap4;
DROP TABLE IF EXISTS area;
reset current_schema;
