#!/bin/bash
base_dir=`dirname $0`
source $base_dir/config/common
time_dir=`date +%s`
mkdir -p $base_dir/logs/$time_dir
for ch in `cat $base_dir/var/client_list`
do
  if test -e $base_dir/var/dist/report/$ch
  then
    ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password rm -rf $remote_base_dir/$ch.logs.tar.gz
    ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password tar czvf $remote_base_dir/$ch.logs.tar.gz $remote_log_dir
    ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password file_download $remote_base_dir/$ch.logs.tar.gz $base_dir/logs/$time_dir
  fi
done
echo $base_dir/logs/$time_dir
$base_dir/parse_log.sh $base_dir/logs/$time_dir
