-- mysql -uroot -h127.0.0.1 -P9030
-- 显示每个fe状态
show frontends;
-- 显示每个be状态
show backends;

create database hello_doris;

use hello_doris;

-- 创建表 
CREATE TABLE session_data
(
    visitorid   SMALLINT,
    sessionid   BIGINT,
    visittime   DATETIME,
    city        CHAR(20),
    province    CHAR(20),
    ip          varchar(32),
    brower      CHAR(20),
    url         VARCHAR(1024)
)
DUPLICATE KEY(visitorid, sessionid) -- 只用于指定排序列，相同的 KEY 行不会合并
DISTRIBUTED BY HASH(sessionid, visitorid) BUCKETS 10;

insert into session_data values
(1, 100000001, '2024-06-28 23:59:59', 'city1', 'province1', '192.168.0.1', 'brower1', 'url1'),
(2, 100000002, '2024-06-28 23:59:59', 'city1', 'province1', '192.168.0.1', 'brower1', 'url1'),
(3, 100000003, '2024-06-28 23:59:59', 'city1', 'province1', '192.168.0.1', 'brower1', 'url1'),
(4, 100000004, '2024-06-28 23:59:59', 'city2', 'province1', '192.168.0.1', 'brower1', 'url1'),
(5, 100000005, '2024-06-28 23:59:59', 'city2', 'province1', '192.168.0.1', 'brower1', 'url1'),
(6, 100000006, '2024-06-28 23:59:59', 'city2', 'province1', '192.168.0.1', 'brower1', 'url1'),
(7, 100000007, '2024-06-28 23:59:59', 'city2', 'province1', '192.168.0.1', 'brower1', 'url1'),
(8, 100000008, '2024-06-28 23:59:59', 'city3', 'province2', '192.168.0.1', 'brower1', 'url1'),
(9, 100000009, '2024-06-28 23:59:59', 'city4', 'province2', '192.168.0.1', 'brower1', 'url1'),
(10, 1000000010, '2024-06-28 23:59:59', 'city5', 'province2', '192.168.0.1', 'brower1', 'url1');

insert into session_data values(12, 1000000012, '2024-06-28 23:59:59', 'city1', 'province1', '192.168.0.1', 'brower1', 'url1');
