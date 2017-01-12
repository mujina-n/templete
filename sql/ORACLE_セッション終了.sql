-- 自分のセッションを調べる
select
sid,serial#,username,osuser,program,machine,terminal
from v$session
where type = 'ユーザ' and MACHINE='ホスト名';


-- ロック状態を調べる①(テーブル絞り)
select object_name,oracle_username,s.sid,s.serial#,s.logon_time,sql_address
from v$locked_object l,dba_objects o, v$session s
where l.OBJECT_ID=o.OBJECT_ID
and l.SESSION_ID=s.SID
and object_name ='テーブル名'
;
-- ロック状態を調べる②(全部)
SELECT
  V$SESSION.SID
  ,V$SESSION.SERIAL#
  ,DBA_OBJECTS.OBJECT_NAME
  ,DBA_OBJECTS.ORACLE_USERNAME
  ,DBA_OBJECTS.SQL_ADDRESS
  ,V$SESSION.LOGON_TIME
  ,V$SESSION.OSUSER
  ,V$SESSION.PROGRAM
FROM
  V$LOCKED_OBJECT
  LEFT JOIN DBA_OBJECTS
    ON V$LOCKED_OBJECT.OBJECT_ID = DBA_OBJECTS.OBJECT_ID
  LEFT JOIN V$SESSION
    ON V$LOCKED_OBJECT.SESSION_ID = V$SESSION.SID
ORDER BY 
  V$SESSION.SID
  ,DBA_OBJECTS.OBJECT_NAME
;

-- ロックの基本情報を表示
SELECT
  SID
  ,TYPE
  ,LMODE
  ,REQUEST
  ,CTIME 
FROM 
  V$LOCK 
WHERE 
  TYPE IN ('TX','TM')
;

-- ロックを起こしているSQL表示
SELECT 
  V$SQLAREA.SQL_TEXT
  ,V$SQLAREA.ADDRESS
FROM
  V$SQLAREA
  ,V$SESSION
  ,V$LOCK
WHERE V$SQLAREA.ADDRESS = V$SESSION.SQL_ADDRESS
AND V$SESSION.SID       = V$LOCK.SID
AND V$LOCK.TYPE        IN ('TX','TM')
;

-- セッション強制終了
alter system kill session 'SID,SERIAL#';

