/*------------------------------------------------------------------------------
セッションIDとスキーマのCPU占有率と詳細を抽出するSQL
------------------------------------------------------------------------------*/
select  
  a.sid as "セッションID"
  ,a.username as "ユーザ名"
  ,a.status as "状態"
  ,trunc((sysdate - a.logon_time)*86400, 3) as "経過時間(sec)"
  ,b.value/100 as "CPU使用時間(sec)"
  ,trunc(b.value/((sysdate - a.logon_time)*86400+1), 3) as "CPU占有率(%)"
  ,c.block_gets as "ブロック取得回数"
  ,c.physical_reads as "物理読み込み回数"
from 
  v$session a
  ,v$sesstat b
  ,v$sess_io c
  ,v$statname d
where 
  a.sid = b.sid and
  b.sid = c.sid and
  b.statistic# = d.statistic# and
  d.name like '%CPU%session'
order by 
  a.username, a.sid
;
/*------------------------------------------------------------------------------
CPU使用時間の長いクエリーを抽出するSQL

【調査対象】
　1回当たりのCPU仕様時間(cpu_time/executions) の値が異常に高いもの(数十秒とか)
　1回当たりのCPU仕様時間(cpu_time/executions) が1秒以上で実行回数(executions)が多いもの
------------------------------------------------------------------------------*/
SELECT
  *
FROM
    (
  SELECT
       sql_id
      ,last_load_time as "最終読込日時"
      ,executions as "実行回数"
--      ,cpu_time as "CPU使用時間"
      ,trunc(cpu_time / executions / 1000000, 3) as "1クエリのCPU実行時間(sec)"
      ,TRANSLATE( sql_text, '#' || CHR(13) || CHR(10), '#' ) as "実行クエリ"
  FROM
      v$SQL
  WHERE
      module = 'JDBC Thin Client'
      AND executions > 0
      AND last_load_time>='2016-04-20/00:00:00'
  ORDER BY
      cpu_time / executions DESC
  )
WHERE
  rownum <= 30
;
