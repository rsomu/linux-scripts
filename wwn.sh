for host in /sys/class/scsi_host/*/device/fc_host/*/port_name
do
  cat $host
done