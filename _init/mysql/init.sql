CREATE DATABASE IF NOT EXISTS sync;
CREATE DATABASE IF NOT EXISTS pushbox;
DROP TABLE IF EXISTS pushbox.__diesel_schema_migrations;
CREATE DEFINER = 'root'@'localhost' EVENT IF NOT EXISTS pushbox.pushbox_cleanup ON SCHEDULE EVERY 1 DAY STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY COMMENT 'Clean up pushbox' DO DELETE FROM pushbox.pushboxv1 WHERE TTL < unix_timestamp();
CREATE DEFINER = 'root'@'localhost' EVENT IF NOT EXISTS fxa_oauth.prune_oauth_authorization_codes ON SCHEDULE EVERY 1 DAY STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY COMMENT 'Prune oauth authorization codes older than 1 day' DO DELETE FROM fxa_oauth.codes WHERE TIMESTAMPDIFF(SECOND, createdAt, NOW()) > 86400;
CREATE DEFINER = 'root'@'localhost' EVENT IF NOT EXISTS sync.not_expire ON SCHEDULE EVERY 1 DAY STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY DISABLE COMMENT 'sync bso not expire' DO UPDATE sync.bso set ttl=2147483647 WHERE  EXISTS ( SELECT data_type FROM INFORMATION_SCHEMA.COLUMNS WHERE table_schema="sync" and table_name="bso" and column_name="ttl" and data_type="int" ) AND ttl !=2147483647 ;
ALTER DEFINER = 'root'@'localhost' EVENT sync.not_expire DISABLE;
