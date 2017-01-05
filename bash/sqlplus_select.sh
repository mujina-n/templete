#!/bin/sh
################################################################################
# sqlplusでデータを取得するサンプルテンプレート
# 　よくある例の社員テーブルから社員番号を取得する内容を記載
################################################################################
# 接続定義
export DB_USER="user"
export DB_PASS="passwd"
export DB_CONN="sid"

MYPID=$(printf "%-05.05d" $$)
BASE_DIR `dirname $0`
IO_FILE=${BASE_DIR}/out.dat

# DB接続
sqlplus -s << _EOF_ > ${IO_FILE}
    ${DB_USER}/${DB_PASS}@${DB_CONN}
    WHENEVER SQLERROR EXIT
    set pagesize 0
    set newpage NONE
    set echo off
    set linesize 1000
    set tab off
    set trimspool on
    set feedback off
    set heading off

    select
        DEPT_NO
    from
        DEPT
    where
        FLG = 1
    ;
    exit
_EOF_

while read line
do
    echo "$line"
done < ${IO_FILE}

exit;