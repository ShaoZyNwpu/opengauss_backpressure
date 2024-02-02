#!/bin/bash

# 获取当前系统时间
CURRENT_DATE=$(date +"%Y-%m-%d_%H%M")
# 根据当前系统时间生成目录路径
BACKUP_PATH="/home/ogtest/shaozy-opengauss/$CURRENT_DATE"

# 设置其他全局变量
NMON_INTERVAL=30
NMON_COUNT=20
OG_PORT=39000

# 创建目录
mkdir -p "$BACKUP_PATH"

# 切换到指定路径
cd "$BACKUP_PATH"

# 运行 nmon，将数据写入文件
nmon -f -s $NMON_INTERVAL -c $NMON_COUNT &

# 在后台运行第一个命令
watch "iostat -x 1 | tee -a io_results.txt" &

# 在后台运行第二个命令
watch -n 1 "gsql -d postgres -p $OG_PORT -c 'select * from local_pagewriter_stat();' | tee -a 3.txt" &

# 在后台运行第三个命令
watch -n 1 "gsql -d postgres -p $OG_PORT -c 'select * from local_candidate_stat();' | tee -a 2.txt" &

# 等待所有后台进程完成
wait
