#!/bin/sh
# ##############################################################################
#       [ＩＤ]  : -
#       [機能]  : 前処理
#       [備考]  : 文字列を数値コードに変換する。
#                 数値コードは連番で振り、KEY:VALUEの形で標準出力し
#                 変換したファイルを出力する。
#       [作成]  : 
#       [バージョン]:  1.0（日付: 2017/12/08）
# ##############################################################################

# 出力情報
MYPID=$(printf "%-05.05d" $$)
BASE_DIR=`dirname $0`
DATE_TIME=`date +"%Y%m%d%H%M%S"`
DATE_DAY=`date +"%Y-%m-%d"`
F_OUT_FORMAT_ROW="out_format_row_${DATE_TIME}.csv"
F_OUT_FORMAT_COL="out_format_col_${DATE_TIME}.csv"
F_OUT_FORMAT_UNQ="out_format_unq_${DATE_TIME}.csv"
F_OUT_FORMAT="out_format_${DATE_TIME}.csv"

# 引数チェック
if [ $# -eq 5 ]; then

    OPT="-i"
    F_ORG=$1
    HED=$2
    SEP=$3
    ROW=$4
    COL=$5
elif [ $# -eq 6 ]; then

    OPT=$1
    F_ORG=$2
    HED=$3
    SEP=$4
    ROW=$5
    COL=$6
    SRC=""
    DST=""
elif [ $# -eq 8 ]; then

    OPT=$1
    F_ORG=$2
    HED=$3
    SEP=$4
    ROW=$5
    COL=$6
    SRC=$7
    DST=$8
else

   OPT="err"
fi

# 設定値チェック
expr ${HED} + 1 > /dev/null 2>&1
if [ $? -ge 2 ]; then

    OPT="err"
fi

if [ ${OPT} != '-i' -a ${OPT} != '-r' ]; then

    echo "usage : $0 [-option] FILE HEAD SEP ROW COL [SRC] [DST]"
    echo "option: -i ファイルに含まれる値を数値コードに変換した内容を標準出力します。"
    echo "           オプション省略時はこのオプション内容が実行されます。"
    echo "        -r 数値コードに変換したファイルを出力します。"
    echo "           SRCとDST設定時はSRCで指定された文字列をDSTに変換します。"
    echo "param : FILE - 入力ファイル"
    echo "        HEAD - ヘッダー行(ない場合は0を指定)"
    echo "        SEP  - 区切り文字(\" \",\";\")"
    echo "        ROW  - 先頭から切り出す行数(n|ALL)"
    echo "        COL  - 切り出す列(\"1[-10][,11,,,n]\"|ALL)"
    echo "        SRC  - 検索文字列"
    echo "        DST  - 置換文字列"
    exit
fi

# 先頭から指定行まで切り出す
if [ "${ROW}" == "ALL" ]; then

    cat "${F_ORG}" > "${F_OUT_FORMAT_ROW}"
else

    head -${ROW} "${F_ORG}"  > "${F_OUT_FORMAT_ROW}"
fi

# 列を切り出す
if [ "${COL}" == "ALL" ]; then

    cat "${F_OUT_FORMAT_ROW}" > "${F_OUT_FORMAT_COL}"
else

    cut "${F_OUT_FORMAT_ROW}" -d"${SEP}" -f"${COL}" > "${F_OUT_FORMAT_COL}"
fi
#-------------------------------------------------------------------------------
# 文字を数字になおす
#-------------------------------------------------------------------------------
ARR_KEY=()
ARR_VAL=()
IDX=0
if [ 0 -eq ${HED} ]; then

    ITEMS=(`head -1 ${F_OUT_FORMAT_COL} | tr -s "${SEP}" " "`)
else

    ITEMS=(`head -${HED} ${F_OUT_FORMAT_COL} | tr -s "${SEP}" " "`)
fi
for ITEM in "${ITEMS[@]}"; do

    # 見出し
    echo "---[${ITEM}]---"

    # 重複行を削除
    if [ 0 -eq ${HED} ]; then
    
        cat "${F_OUT_FORMAT_COL}" | cut -d"${SEP}" -f`expr ${IDX} + 1` | sort | uniq > ${F_OUT_FORMAT_UNQ}
    else

        tail -n +`expr ${HED} + 1` "${F_OUT_FORMAT_COL}" | cut -d"${SEP}" -f`expr ${IDX} + 1` | sort | uniq > ${F_OUT_FORMAT_UNQ}
    fi

    # 名前に区分(数値)を振り分ける
    VAL=0
    KEYS=""
    VALS=""
    while read LINE
    do
        KEY=`echo "${LINE}"`
        echo "${KEY} : ${VAL}"

        KEYS+="${KEY} "
        VALS+="${VAL} "
        VAL=`expr ${VAL} + 1`
    done < ${F_OUT_FORMAT_UNQ}

    ARR_KEY[IDX]="${KEYS}"
    ARR_VAL[IDX]="${VALS}"
    IDX=`expr ${IDX} + 1`
done


if [ ${OPT} == '-r' ]; then

    echo -n "変換ファイルを出力します Y/N>"
    read INPUT
    if [ "$INPUT" != "Y" -a "$INPUT" != "y" ]; then
         echo "キャンセルされました"
         exit
    fi
else
    exit
fi
#-------------------------------------------------------------------------------
# 変換
#-------------------------------------------------------------------------------
while read LINE
do

    IDX=0
    VAL_CAST=""
    ITEMS=(`echo "${LINE}" | tr -s "${SEP}" " "`)
    for ITEM in "${ITEMS[@]}"; do

        isNum=false

        # 数値判定1(整数)
        expr ${ITEM} + 1 > /dev/null 2>&1
        if [ $? -lt 2 ]; then

            isNum=true
        fi
        # 数値判定2(実数)
        echo "${ITEM}" | grep -v "[^0-9\.\-]" | grep -v "^\." | grep -v "\-\." > /dev/null 2>&1
        if [ $? -eq 0 ]; then

            RET_BC=`echo "${ITEM} + 1" | bc 2>&1`
            if [[ "$BC_RESULT" != "error" ]]; then

                isNum=true
            fi
        fi

        # ファイルの項目が数字ではない場合
        # かつ引数の検索文字列と一致しない場合は変換
        if [ ${isNum} != true -a ${ITEM} != "${SRC}" ]; then

            # 変換表の区分(数値)に変換
            IDX_CAST=0
            KEYS=(${ARR_KEY[IDX]})
            VALS=(${ARR_VAL[IDX]})
            for KEY in "${KEYS[@]}"; do

                if [ "${KEY}" == "${ITEM}" ]; then

                    VAL_CAST+="${VALS[IDX_CAST]}${SEP}"
                    break
                fi
                IDX_CAST=`expr ${IDX_CAST} + 1`
            done
        else

            VAL_CAST+="${ITEM}${SEP}"
        fi

        IDX=`expr ${IDX} + 1`
    done

    echo "${VAL_CAST}" >> "${F_OUT_FORMAT}"
done < "${F_OUT_FORMAT_COL}"

# 中間出力ファイルの削除
rm -f "${F_OUT_FORMAT_ROW}"
rm -f "${F_OUT_FORMAT_COL}"
rm -f "${F_OUT_FORMAT_UNQ}"

# 検索文字列を置換文字列で一括置換
if [ "${SRC}" != "" -a "${DST}" != "" ]; then

    sed -i -e "s/${SRC}/${DST}/g" "${F_OUT_FORMAT}"
fi
exit
