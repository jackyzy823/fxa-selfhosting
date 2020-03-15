CREATE DATABASE IF NOT EXISTS sync;
CREATE DATABASE IF NOT EXISTS pushbox;
USE pushbox;
SET GLOBAL event_scheduler = ON;
CREATE EVENT IF NOT EXISTS pushbox_cleanup 
	ON SCHEDULE 
		EVERY 1 DAY STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
	COMMENT 'Clean up pushbox'
	DO
		DELETE from pushbox.pushboxv1 where TTL < unix_timestamp();