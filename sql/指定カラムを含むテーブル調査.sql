-- 全てのテーブルを対象に出現回数が多いカラムを降順に取得するSQL
select 
  COLUMN_NAME
  ,count(*) cnt
from 
  ALL_TAB_COLUMNS a
where 
  OWNER ='スキーマ名' 
  and TABLE_NAME in (
    select 
      OBJECT_NAME 
    from 
      ALL_OBJECTS 
    where 
      OWNER = a.OWNER 
    and OBJECT_TYPE='TABLE' )
group by column_name
order by cnt desc
;
-- 指定したカラムが含まれるテーブルを取得するSQL
select 
  table_name
from 
  all_tab_columns a
where 
  owner ='スキーマ名' 
  and column_name = '検索カラム名'
  and table_name in (
    select 
    OBJECT_NAME 
    from 
    ALL_OBJECTS 
    where 
    OWNER = a.OWNER 
    and OBJECT_TYPE='TABLE' )
order by table_name
;
