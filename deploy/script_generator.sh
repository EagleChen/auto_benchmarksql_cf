#!/bin/bash -x
base_dir=`dirname $0`
source $base_dir/../config/common
# index, script_file_prefix type
index=$1
file_prefix=$2
file_type=$3
load_var_name=\$load_$file_type
load_t_num=`eval echo $load_var_name`
# generate the prepare script
prepare_script=$file_prefix.prepare.sh
cat > $prepare_script << EOF
#!/bin/bash
export JAVA_HOME=$driver_remote_in/$jdk_dir
cd $driver_remote_in/$driver_name/run
chmod +x ./loadData.sh
./runSQL.sh $remote_prop_dir/`basename $file_prefix` sqlTableDrops
./runSQL.sh $remote_prop_dir/`basename $file_prefix` sqlTableCreates 
./runSQL.sh $remote_prop_dir/`basename $file_prefix` sqlIndexCreates
EOF
# generate the preload script
preload_script=$file_prefix.preload.sh
cat > $preload_script << EOF
#!/bin/bash
export JAVA_HOME=$driver_remote_in/$jdk_dir
cd $driver_remote_in/$driver_name/run
chmod +x ./loadData.sh
rm -rf $remote_log_dir/`basename $file_prefix`.loadData.log
./loadData.sh $remote_prop_dir/`basename $file_prefix` -w$load_warehouse -log$remote_log_dir/`basename $file_prefix`.loadData.log
EOF
# generate the benchmark script
benchmark_script=$file_prefix.benchmark.sh
cat > $benchmark_script << EOF
#!/bin/bash
export JAVA_HOME=$driver_remote_in/$jdk_dir
cd $driver_remote_in/$driver_name/run
chmod +x ./runBenchmark.sh
mkdir -p $remote_log_dir/`basename $file_prefix`.benchmark
rm -rf $remote_log_dir/`basename $file_prefix`.benchmark/*
./runBenchmark.sh $remote_prop_dir/`basename $file_prefix` -w$load_warehouse -log$remote_log_dir/`basename $file_prefix`.benchmark -m$load_time -q$load_cycle_time -f$load_scale_factor -d$load_delivery_weight -t$load_t_num
EOF

