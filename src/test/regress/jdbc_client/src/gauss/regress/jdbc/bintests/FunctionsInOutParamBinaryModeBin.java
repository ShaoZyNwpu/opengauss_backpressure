package gauss.regress.jdbc.bintests;

import gauss.regress.jdbc.IBinaryTest;
import gauss.regress.jdbc.utils.DatabaseConnection4Test;

public class FunctionsInOutParamBinaryModeBin implements IBinaryTest {
	/**
	 * This test is added to test the functionality of replacing the return value of a function when
	 * The function returns a record that contains client logic fields
	 */
	@Override
	public void execute(DatabaseConnection4Test conn) {
		conn.connectInBinaryMode();
		BinUtils.createCLSettings(conn);
		
		conn.executeSql("CREATE TABLE t_processed (name text, "
				+ "val INT ENCRYPTED WITH (column_encryption_key = cek1, encryption_type = DETERMINISTIC), val2 INT)");
		conn.executeSql("insert into t_processed values('one',1,10),('two',2,20),('three',3,30),('four',4,40),"
				+ "('five',5,50),('six',6,60),('seven',7,70),('eight',8,80),('nine',9,90),('ten',10,100)");

		conn.executeSql("CREATE TABLE t_processed_b (name text, "
				+ "val text ENCRYPTED WITH (column_encryption_key = cek1, encryption_type = DETERMINISTIC), val2 INT)");
		conn.executeSql("INSERT INTO t_processed_b VALUES('name1', 'one', 10),('name2', 'two', 20),"
				+ "('name3', 'three', 30),('name4', 'four', 40),('name5', 'five', 50),('name6', 'six', 60),"
				+ "('name7', 'seven', 70),('name8', 'eight', 80),('name9', 'nine', 90),('name10', 'ten', 100)");
		conn.executeSql("CREATE OR REPLACE FUNCTION f_processed_in_out_1param( out1 OUT int,in1 int) "
				+ "AS 'SELECT val from t_processed  where val = in1 LIMIT 1' LANGUAGE SQL");
		conn.executeSql("CREATE OR REPLACE FUNCTION f_processed_in_out(out1 OUT int,in1 int,  out2 OUT int) "
				+ "AS 'SELECT val, val2 from t_processed where val = in1 LIMIT 1' LANGUAGE SQL");
		conn.executeSql("CREATE OR REPLACE FUNCTION f_processed_in_out_b(out1 OUT text, out2 OUT int,in1 text, in2 text) "
				+ "AS 'SELECT val, val2 from t_processed_b where val = in1 or name = in2 LIMIT 1' LANGUAGE SQL");

		conn.executeSql("CREATE OR REPLACE FUNCTION f_processed_in_out_plpgsql(in1 int, out out1 int, in2 int, out out2 int)"
		+ "as $$ "
		+ "begin "
		+ "select val, val2 INTO out1, out2 from t_processed where val = in2 or val = in1 limit 1; "
		+ "end;$$ "
		+ "LANGUAGE plpgsql");

		conn.executeSql("CREATE OR REPLACE FUNCTION "
				+ "f_processed_in_out_plpgsql2(out out1 t_processed.val%TYPE, "
				+ "out out2 t_processed.val%TYPE, in1 t_processed.val%TYPE) "
		+ "as $$ "
		+ "begin "
		+ "  select val, val2 INTO out1, out2 from t_processed where val = in1 limit 1; "
		+ "end;$$ "
		+ "LANGUAGE plpgsql");

		conn.executeSql("CREATE OR REPLACE FUNCTION f_processed_in_out_aliases_plpgsql(out out1 int, in1 int,out out2 int) as "
		+ "$BODY$ "
		+ "DECLARE "
		+ " val1 ALIAS FOR out1; "
		+ " input_p ALIAS for in1; "
		+ "begin "
		+ "  select val, val2 INTO val1, out2 from t_processed where val = input_p; "
		+ "end; "
		+ "$BODY$ "
		+ "LANGUAGE plpgsql; ");
		conn.fetchData("select proname, prorettype, proallargtypes, prorettype_orig, proallargtypes_orig "
				+ "FROM pg_proc "
				+ "LEFT JOIN gs_encrypted_proc ON pg_proc.Oid = gs_encrypted_proc.func_id "
				+ "WHERE proname IN "
				+ "('f_processed_in_out', 'f_processed_in_out_plpgsql', 'f_processed_in_out_plpgsql2', "
				+ "'f_processed_in_out_aliases_plpgsql', 'f_processed_in_out_1param') ORDER BY proname");
		
		conn.fetchData("SELECT f_processed_in_out_1param(2)");
		conn.fetchData("SELECT f_processed_in_out(5)");
		conn.fetchData("SELECT f_processed_in_out_b('ten','name70')");
		conn.fetchData("SELECT f_processed_in_out_plpgsql(17,3)");
		conn.fetchData("SELECT f_processed_in_out_plpgsql2(6)");
		conn.fetchData("SELECT f_processed_in_out_aliases_plpgsql(4)");
		conn.executeSql("DROP TABLE t_processed CASCADE");
		conn.executeSql("DROP TABLE t_processed_b CASCADE");
		conn.executeSql("DROP FUNCTION f_processed_in_out_1param");
		conn.executeSql("DROP FUNCTION f_processed_in_out");
		conn.executeSql("DROP FUNCTION f_processed_in_out_b");
		conn.executeSql("DROP FUNCTION f_processed_in_out_plpgsql");
		conn.executeSql("DROP FUNCTION f_processed_in_out_plpgsql2");
		conn.executeSql("DROP FUNCTION f_processed_in_out_aliases_plpgsql");
		BinUtils.dropCLSettings(conn);
	}
}
