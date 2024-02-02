CREATE FOREIGN TABLE VARCHAR_TBL(f1 varchar(1));
CREATE FOREIGN TABLE T1 (STRING VARCHAR(1020));

INSERT INTO T1 VALUES ('To change the types of two existing columns in one operation: 
	ALTER TABLE T1
	    ALTER COLUMN STRING  TYPE varchar(80);');

SELECT * FROM T1;

ALTER TABLE T1 ADD COLUMN STR1 varchar(80);

SELECT * FROM T1;

DROP FOREIGN TABLE T1;
DROP FOREIGN TABLE VARCHAR_TBL;






