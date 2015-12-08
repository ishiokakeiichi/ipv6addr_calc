#!/bin/sh

interface='eth1'
[ $# -ge 1 ] && interface=$1

inet6=`ip addr show ${interface} | grep inet6`
[ $? -ne 0 ] && exit 1

# (7 + 1 from Link Local prefix) + 40 = 48bit
prefix=`echo $inet6  |awk '{print substr($2,0,2)}'`
GlobalIDHash='ce8e9eeada'

# 16bit
SubnetID=''

# 64bit from Link Local
InterfaceID=''
LinkLocal=`echo $inet6 |awk '{s = gsub(/\/64$/, "" , $2);print $2}'`
#LinkLocal=`ip addr show ${interface} |grep inet6 |awk '{s = gsub(/\/64$/, "" , $2);print $2}'`
IFS_ORIGINAL=$IFS;IFS=:;arr=($LinkLocal);IFS="$IFS_ORIGINAL"
len=${#arr[@]}
from=$(( ${#arr[@]} - 4 ))

for i in `seq $from $(($len -1))`; do
  if [ -z $InterfaceID ]; then
    InterfaceID=${arr[$i]}
  else 
    InterfaceID=${InterfaceID}:${arr[$i]}
  fi
done

function hashToV6() {
  if [[ $((`expr length $1` % 4)) -ne 0 ]];then 
    echo "ERROR"
    exit 1
  fi

  inc=$((`expr length $1` /4))
  rx=''
  xx=''
  str=$1
  for i in `seq 1 $inc`; do
   rx="${rx}\([0-9a-f]\{4\}\)"
   if [  -z  $xx ]; then
     xx="\\${i}"
   else
     xx="${xx}:\\${i}"
   fi 
  done
  echo $str |sed -e "s/${rx}/${xx}/"
  
}
Prefix_AND_GlobalID=`hashToV6 ${prefix}${GlobalIDHash}`
echo ${Prefix_AND_GlobalID}:${SubnetID}:${InterfaceID}

