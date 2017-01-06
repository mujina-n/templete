#!/bin/sh
#-------------------------------------------------------------------------------
# よく使うシェル内のコマンドのタイムアウトを設定するサンプル
# 　usage : source ./timeout.sh
# 　　　　　timeout SEC_TIMEOUT CMD
# 　　　　　　SEC_TIMEOUT - タイムアウト秒数
# 　　　　　　CMD         - 実行コマンド 
#-------------------------------------------------------------------------------
timeout()
{
    count_timeout=$1
    shift 1;
    $@ &
    pid=$!
    count=0
    while [ $count -lt $count_timeout ]
    do
        isalive=`ps -ef | grep $pid | grep -v grep | wc -l`
        if [ $isalive -eq 1 ]; then
            count=`expr $count + 1`
            sleep 1
        else
            count=`expr $count_timeout`
        fi
    done
    isalive=`ps -ef | grep $pid | grep -v grep | wc -l`
    if [ $isalive -eq 1 ]; then
        kill -kill $pid
        wait $pid
        return 9;
    else
        return 0;
    fi
}
