#!/bin/sh
################################################################################
# ログから操作履歴の存在有無を調べるサンプルテンプレート
# 　よくある例の社員テーブルから対象の社員番号を取得して調査する内容を記載
#
# 以下、処理概要
# 　・引数に会社コードを設定
# 　・会社コードに該当する対象の社員番号の一覧をファイル出力
# 　　(この例では先頭'S'は対象外)
# 　・前回結果ファイルより追加差分のみ対象としてログファイルを調査
# 　・結果ファイルにログファイルに存在した社員番号を出力
################################################################################

# 接続定義
export DB_USER="user"
export DB_PASS="passwd"
export DB_CONN="server:1521/sid"

# 出力情報
MYPID=$(printf "%-05.05d" $$)
BASE_DIR=`dirname $0`
DATE_TIME=`date +"%Y%m%d%H%M%S"`
DATE_DAY=`date +"%Y-%m-%d"`
AP=$0
IO_FILE=${BASE_DIR}/${AP}.${DATE_TIME}.1.dat
CHK_FILE=${BASE_DIR}/${AP}.${DATE_TIME}.2.dat
APLOG_DIR="/var/log/${AP}.log"

# 引数チェック
if [ $# -eq 1 ]; then

    export OPT="-i"
    export KEY=$1
elif [ $# -eq 2 ]; then

    export OPT=$1
    export KEY=$2
else
    export OPT="err"
fi

if [ ${OPT} != '-i' -a ${OPT} != '-s' ]; then

    echo "usage : ${AP} [option] KEY"
    echo "option: -i  実行前に確認してチェックを開始します。"
    echo "            オプション省略時はこのオプションの内容が実行されます。"
    echo "        -s  実行確認なしにチェックします。"
    exit
fi

if [ ${OPT} != '-s' ]; then

    echo -n "処理を実行しますか? Y/N>"
    read INPUT
    if [ "$INPUT" != "Y" -a "$INPUT" != "y" ]; then
         echo "キャンセルされました"
         exit
    fi
fi
# 実行前に前回実行のファイルパス取得
ls -tr ${BASE_DIR}/${AP}.*.1.dat > /dev/null 2>&1
if [ $? -eq 0 ]; then
    LAST_FILE=`ls -tr ${BASE_DIR}/${AP}.*.1.dat | tail -1`
else
    LAST_FILE="nothing"
fi

# 環境変数設定
export DEPT_NO=$1
sqlplus -s << _EOF_ >> ${IO_FILE}
    ${DB_USER}/${DB_PASS}@${DB_CONN}
    whenever sqlerror exit
    set feedback off
    set serveroutput on;
    set line 300;

    declare

        sql_code number;
        sql_errm varchar2(2000);
        sql_stmt varchar2(2048);
        ----------------------------------------------------------------------------
        -- メイン関数
        ----------------------------------------------------------------------------
        procedure main
        is
            -- カーソル宣言
            TYPE type_cur_user is ref cursor;
            cur_user type_cur_user;
            TYPE type_user is record (
                company_cd DEPT.COMPANY_CD%TYPE,
                section_cd DEPT.SECTION_CD%TYPE,
                dept_no DEPT.DEPT_NO%TYPE
            );
            rec_user type_user;

            -- 変数宣言
            dept_no DEPT.DEPT_NO%TYPE;

        begin
            dept_no := '${DEPT_NO}';
            open cur_user for '
                SELECT
                  DEPT.COMPANY_CD
                  ,DEPT.SECTION_CD
                  ,DEPT.DEPT_NO
                FROM
                  DEPT
                WHERE
                  DEPT.COMPANY_CD=:1
                  AND NOT REGEXP_LIKE(DEPT.DEPT_NO,''^S'')'
                using company_cd
                ;

            loop
                fetch cur_user into rec_user;
                if cur_user%NOTFOUND or cur_user%NOTFOUND is null then
                    exit;
                end if;

                -- 出力
                dbms_output.put_line(
                    rec_user.company_cd
                    || ',' || rec_user.section_cd
                    || ',' || rec_user.dept_no);

            end loop;
            close cur_user;

        exception
            when OTHERS then
            sql_code := SQLCODE;
            sql_errm := SQLERRM;
            dbms_output.put_line('[FETCH_ERROR:' || sql_code || '] ' || sql_errm);
        end main;
    ---------
    -- 起動
    ---------
    begin

        main;
    end;
    /

    exit;

_EOF_


# 件数を出力
echo "件数:`wc -l ${IO_FILE} | cut -d" " -f 1`"

if [ ${OPT} != '-s' ]; then

    echo -n "ログフォルダを検索しますか?(初回は時間かかります) Y/N>"
    read INPUT
    if [ "$INPUT" != "Y" -a "$INPUT" != "y" ]; then
         echo "キャンセルされました"
         exit
    fi
fi

if [ -e ${LAST_FILE} ]; then
    # 前回結果ファイルがある場合、追加差分のみ対象
    diff ${LAST_FILE} ${IO_FILE} | grep '^>' | sed -e 's/^> *//g' > ${CHK_FILE}
else
    # 前回結果ファイルがない場合は全て対象
    CHK_FILE="${IO_FILE}"
fi

# ログフォルダを検索して存在する場合、標準出力
while read line
do
    DEPT_NO=`echo "${line}" | cut -d"," -f 3`
    find ${APLOG_DIR} -name ${AP}.log.${DATE_DAY}-[0-2][0-9] | xargs grep -e "[^S_]DEPT_NO[ ]*=[ ]*'${DEPT_NO}'" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "${line}"
    fi
done < $CHK_FILE

if [ "${IO_FILE}" != "${CHK_FILE}" ]; then
    rm -f ${CHK_FILE};
fi
exit;
