j=1
for i in `multipath -ll $1 | grep ' running' | awk ' { print "/sys/block/" $3 "/device/delete" } '`;
do
arr[$j]=$i
((j++))
echo $i
done
#echo ${arr[@]} # Elements in the array
#echo ${#arr[@]}  # Number of elements in the array
for (( i=1; i<=${#arr[@]};i++ ))
do
# echo $i
#echo ${arr[$i]}
  echo 1 > ${arr[$i]}
done