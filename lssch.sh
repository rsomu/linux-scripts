for i in `multipath -ll $1 |grep 'running' |awk ' { print "/sys/block/" $3 "/queue/scheduler" } '`
do
  echo $i ":" `cat $i`
done