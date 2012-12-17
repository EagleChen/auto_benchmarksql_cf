#!/bin/bash -x
bin_dir=`dirname $0`
source $bin_dir/../config/common

dist_dir=$base_dir/var/dist
for action in prepare preload benchmark report
do
  mkdir -p $dist_dir/$action
  rm -rf $dist_dir/$action/*
done

sed -i "/^$/d" $bae_dir/config/client_nodes
client_ln_idx=0
for load_type in heavy medium light idle
do
  inst_num_var=\$inst_$load_type
	inst_type_num=`eval echo $inst_num_var`
	for i in `seq 1 $inst_type_num`
	do
    echo $i
	  ci=$(($client_ln_idx % $client_num + 1))
	  ch=`cat $base_dir/config/client_nodes | grep -v '^$' | sed -n "${ci},${ci}p"`
	  for action in prepare preload benchmark report
	  do
      if test $load_type = "idle" -a $action == "benchmark" -o $load_type = "idle" -a $action == "report"
      then
        echo "idle instance has no benchmark and report scripts"
      else
	      echo "nohup $remote_script_dir/${service_type}.${inst_num}.$load_type.$i.${action}.sh 1>$remote_log_dir/${service_type}.${inst_num}.$load_type.$i.$action.log 2>&1 &" >> $dist_dir/$action/$ch
      fi
	  done
    client_ln_idx=$(($client_ln_idx + 1))
	done
done

cat > $base_dir/var/stop.sh << EOF
export JAVA_HOME=$driver_remote_in/$jdk_dir
ps xa | grep java | awk '{print \$1}' | xargs kill 9
ps xa | grep $remote_base_dir | awk '{print \$1}' | xargs kill 9
EOF

for ch in `cat $base_dir/config/client_nodes | grep -v '^$' | head -n $client_num`
do
  for action in prepare preload benchmark report
  do
    ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password rm -rf $remote_base_dir/$action.sh
    ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password file_upload $dist_dir/$action/$ch $remote_base_dir/$action.sh 
    ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password chmod +x  $remote_base_dir/$action.sh
  done

  ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password rm -rf $remote_base_dir/stop.sh
  ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password file_upload $base_dir/var/stop.sh $remote_base_dir/stop.sh 
  ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password chmod +x  $remote_base_dir/stop.sh
done


