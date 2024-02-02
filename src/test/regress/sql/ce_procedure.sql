-------------------------
-- unsupport procedure --
-------------------------

---------------------forall------------------------
SET CHECK_FUNCTION_BODIES TO ON;

\! gs_ktool -d all
\! gs_ktool -g

DROP CLIENT MASTER KEY procedureCMK CASCADE;
CREATE CLIENT MASTER KEY procedureCMK WITH ( KEY_STORE = gs_ktool , KEY_PATH = "gs_ktool/1" , ALGORITHM = AES_256_CBC);
CREATE COLUMN ENCRYPTION KEY procedureCEK WITH VALUES (CLIENT_MASTER_KEY = procedureCMK, ALGORITHM = AEAD_AES_256_CBC_HMAC_SHA256);

CREATE TABLE IF NOT EXISTS Image(
id INT,
title VARCHAR(30)    ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = procedureCEK , ENCRYPTION_TYPE = DETERMINISTIC),
Artist TEXT          ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = procedureCEK , ENCRYPTION_TYPE = DETERMINISTIC),
description TEXT     ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = procedureCEK , ENCRYPTION_TYPE = DETERMINISTIC),
DataTime DATE,
Xresolution INT      ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = procedureCEK , ENCRYPTION_TYPE = DETERMINISTIC),
Yresolution INT      ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = procedureCEK , ENCRYPTION_TYPE = DETERMINISTIC),
ResolutionUnit VARCHAR(8)    ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = procedureCEK , ENCRYPTION_TYPE = DETERMINISTIC),
ImageSize INT        ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = procedureCEK , ENCRYPTION_TYPE = DETERMINISTIC),
Alititude INT        ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = procedureCEK , ENCRYPTION_TYPE = DETERMINISTIC),
Latitude FLOAT4      ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = procedureCEK , ENCRYPTION_TYPE = DETERMINISTIC),
Longitude FLOAT4     ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = procedureCEK , ENCRYPTION_TYPE = DETERMINISTIC),
ImagePath VARCHAR(100)       ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = procedureCEK , ENCRYPTION_TYPE = DETERMINISTIC)
);

INSERT INTO Image VALUES ( 1, 'img4214189','IDO', 'it is a flower in roadsize', '2019-11-07', 1080, 1440, 'px', 776, 108, 23.45, 120.24, '/DCIM/Camera/img4214189');
INSERT INTO Image VALUES ( 2, 'img4214190','IDO', 'the park', '2019-11-10', 1080, 1920, 'px', 187, 292, 45.28, 102.24, '/DCIM/Camera/img4214190');
INSERT INTO Image VALUES ( 3, 'img4214191','ZAVIER', 'the mountain','2019-11-30', 1080, 1920, 'px', 793, 686, 28.86, 108.76, '/DCIM/Camera/img4214191');
INSERT INTO Image VALUES ( 4, 'img4214192','AVI', 'a dog', '2019-11-26 16:10:22', 1920, 1080, 'px', 184, 949, 30.67, 109.01, '/DCIM/Camera/img4214192');
INSERT INTO Image VALUES ( 5, 'img4214193','AVI', 'a cat', '2019-11-27', 720, 240, 'px', 805, 292, 45.26, 102.24, '/DCIM/Camera/img4214193');
INSERT INTO Image VALUES ( 6, 'img4214194','ELI', 'a beautiful girl', '2019-11-25', 480, 1024, 'px', 1058, 40, 34.71, 116.72, '/DCIM/Camera/img4214194');
INSERT INTO Image VALUES ( 7, 'img4214195','ELI', 'home', '2019-11-20 10:45:10', 360, 360, 'px', 773, 1320, 28.62, 106.39, '/DCIM/Camera/img4214195');

CREATE OR REPLACE PROCEDURE INSERT_IMAGE
(
    id_param     IN   INTEGER,
    title_param  IN   VARCHAR(30),
	artist_param IN   TEXT,
	description_param  IN   TEXT,
	dataTime_param     IN   DATE,  
	xresolution_param  IN   INT,
	yresolution_param  IN   INT,
	resolution_unit_param  IN   VARCHAR(8),
	imageSize_param  IN   INT,
	alititude_param  IN   INT,
	latitude_param   IN   FLOAT4,
	longitude_param  IN   FLOAT4,
	imagePath_param  IN   VARCHAR(100)
)
AS
BEGIN
	INSERT INTO Image VALUES ( id_param, artist_param, artist_param, description_param, dataTime_param, xresolution_param, yresolution_param, resolution_unit_param, imageSize_param, alititude_param, latitude_param, longitude_param, imagePath_param);
END;
/
CALL INSERT_IMAGE(8, 'img4214196','ZAVIER', 'a river', '2019-11-22 12:45:26', 720, 720, 'px', 1244, 510, 29.75, 105.79, '/DCIM/Camera/img4214196');

CREATE OR REPLACE PROCEDURE UPDATE_DESCRIPTION(title_param IN VARCHAR(30), description_param IN TEXT, result OUT VARCHAR(30))
AS
BEGIN
	UPDATE Image SET description = description_param WHERE title = title_param;
	result:= title_param;
END;
/

CALL UPDATE_DESCRIPTION('img4214189','the description is update', result);

create function select_data() returns table(id_param int, artist_param text)
as
$BODY$
begin
return query(select id, Artist from Image order by id);
end
$BODY$
LANGUAGE plpgsql;

call select_data();

DROP PROCEDURE IF EXISTS INSERT_IMAGE;
DROP PROCEDURE IF EXISTS update_description();
DROP FUNCTION IF EXISTS select_data();
DROP TABLE IF EXISTS Image;
DROP COLUMN ENCRYPTION KEY procedureCEK;
DROP CLIENT MASTER KEY procedureCMK;

\! gs_ktool -d all
