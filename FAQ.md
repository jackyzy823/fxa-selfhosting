1. Why `Send Tabs` not work?

If your mysql db has been restarted, then `Send Tabs` will not work as expected.

Because in the version of mysql we used (5.7), there's a bug that `AUTO_INCREMENT` are not persisted. (just google mysql `auto_increment` counter resetting after server restart)

So if we delete pushboxv1 records (by a scheduled job in init.sql), after mysql restarted it will find out current `AUTO_INCREMENT` to be max(idx) which is 0 if there's no records.

However in client side, the index is persisted. so client will ask records >= index ,  in db the index will always < index , until you made a lot of `Send Tabs` to make index great enough (the lower id will never works). It cause `Send Tabs` not worl

How to temp fix?

check nginx logs see "/acccount/device/commands?index=<required_id>" , 

make the minimal idx of pushboxv1 >= `required_id` by `update pushboxv1 set idx = idx+<offset>` , then  `alter table pushboxv1 AUTO_INCREMENT = max_id`

`offset` =  select `<required_id>` - min(id) from pushboxv1
`max_id` = select max(id)+1 from pushboxv1

How to mitigate?
	1. do not do clean up job (defined in init.sql)  , so the records keep , and mysql will calc right idx from current records.
	2. or a very long `PUSHBOX_TTL`
	3. upgrade mysql to 8.0 ( https://dba.stackexchange.com/questsions/80564)

2. Why channelserver keep restarting.

Because the latest channelserver update rust version , but not debian version which causing a glibc mismatch issue.

How to mitigate?

use sha256 tag `docker pull mozilla/channelserver@sha256:01f9251637cc3679b8cf31493569a79a27b41f952d4eb3d5306e1ee8d9d3feea`

