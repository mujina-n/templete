-- 各制約の一覧を取得するSQL
-- (取得したいKEYによりCONSTRAINT_TYPEの種類を選択)
-- 　P:主キー
-- 　U:一意キー
-- 　R:外部キー
-- 　C:CHECK、NOT NULL
select
  cons.TABLE_NAME
  ,cons_col.COLUMN_NAME
from
  USER_CONSTRAINTS cons
  ,USER_CONS_COLUMNS cons_col
where
  cons.TABLE_NAME    = cons_col.TABLE_NAME
  and cons.CONSTRAINT_NAME = cons_col.CONSTRAINT_NAME
  and cons.CONSTRAINT_TYPE = 'P'
order by
  cons_col.TABLE_NAME
  ,cons_col.COLUMN_NAME
;