# NOTE: this will  only execute  when creating new db (mysql_data folder not exists) ! will not execute when container rebuild/recreate/restart
CREATE DATABASE IF NOT EXISTS sync;
USE sync;
SET GLOBAL event_scheduler = ON;
# This is for python version syncstorage
# reference: https://mozilla-services.readthedocs.io/en/latest/storage/apis-1.5.html#basic-storage-object
# https://github.com/mozilla-services/server-syncstorage/blob/02d617d655da361fddaa757b92fdd6c8ad46572c/syncstorage/storage/sql/__init__.py#L733
# However MAX_TTL means 'Fri Jul 18 13:20:00 2036' which is not sufficient maybe.
# They confused ttl and expiry_time in database and bso
CREATE EVENT IF NOT EXISTS bso_ttl
	ON SCHEDULE
		EVERY 1 DAY STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
	COMMENT 'set all bso ttl to 2100000000 which means forever'
	DO
		UPDATE sync.bso set ttl = 2100000000 where ttl != 2100000000;