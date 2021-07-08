#!/bin/sh

##########################################################
# Author: LiGuang
# Create Date: 2021/06/28
# Version: 1.0
##########################################################
# bash CPU_log.sh '/home/guangl/code/log_cpu.csv'
#param('/xxx/*.csv'): folder and csv file name to save the memory information


log_file_name=$1


#echo $process_id

if [ -f $log_file_name ]; then
    rm $log_file_name
fi

if [ ! -f $log_file_name ]; then
    touch $log_file_name
fi

#PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND 
#echo "PID    RES   %CPU   %MEM i    TIME+  COMMAND  ">>$log_file_name

#echo "process exist:"$process_exist
#
echo "GPUUsage(MB), MemoryUsage(MB),MaxGPUUsage(MB),MaxMemoryusage(MB),Time(s) ">>$log_file_name


count=$((0))
gpu_memory_total=$((0))
cpu_memory_total=$((0))
cpu_usage_total=$((0))
max_cpu_memory=$((0))
max_gpu_memory=$((0))
max_cpu_usage=$((0))

start_runningtime=$((0))
end_runningtime=$((0))

start_runningtime=$(date "+%s")

max_all_cpu_memory=$((0))
max_all_gpu_memory=$((0))
min_all_cpu_memory=$((10**16))
min_all_gpu_memory=$((10**16))
mean_all_cpu_memory=$((0))
mean_all_gpu_memory=$((0))
count_allmax=$((1))

current_mean_listening_gpu_memory=$((0))
count_listening=$((0))
listening=$((1))
while(($listening))#((1))
do
    sleep 1
    gpu_memory=$(nvidia-smi -i 0 --format=csv,noheader,nounits --query-gpu=memory.used)
    #cpu_memory=$(top -n 1 -b |grep $process_id |awk '{print $6","$9","$11}')
    #echo $gpu_memory","$cpu_memory >>$log_file_name
    
    cpu_memory=$(awk '/MemTotal/{total=$2}/MemFree/{free=$2}/Buffers/{buffers=$2}/^Cached/{cached=$2}END{print (total-free-buffers-cached)/1024}'  /proc/meminfo)

    echo $gpu_memory","$cpu_memory


    #
    input=$cpu_memory
    lastchar=${input#${input%?}}
    if [ -z "${lastchar//[0-9]/}" ]; then
       value=${input}
    else
        #get last char as units
        lastchar=${input#${input%?}}
        #remove last char
        num=${input%${lastchar}}
        #last char is K,M,G
    case $lastchar in
    K|k)
    #value=$(($num / 1024))
    value=$(echo "scale=8; $num/1024" |bc)
    ;;
    m|M)
    #value=$(($num))
    value=$(echo "scale=8; $num*1" |bc)
    ;;
    g|G)
    #value=$(($num * 1024))
    value=$(echo "scale=8; $num*1024" |bc)
    ;;
    t|T)
    #value=$(($num))
    value=$(echo "scale=8; $num*1024*1024" |bc)
    ;;
    #other unit error
    *)
    echo "Wrong unit"
    value=$(echo "scale=8; $num*1" |bc)
    #exit 1
    ;;
esac
fi

echo $value
cpu_memory=$value
    #

    #Record maximun value of each iterm
    if (($max_gpu_memory < $gpu_memory))
        then
	   max_gpu_memory=$gpu_memory
	   #echo $max_gpu_memory
    fi

    if [ `echo "$max_cpu_memory < $cpu_memory"|bc` -eq 1 ] ; then
    #echo  "$a < $b "
    max_cpu_memory=$cpu_memory
    else
    echo "$max_cpu_memory > $cpu_memory "

    fi

   
    #

    count=$(($count+1))
    #echo "count number:"$count
    gpu_memory_total=$(($gpu_memory_total+$gpu_memory))
    #echo "total gpu memory:"$gpu_memory_total
    #cpu_memory_total=$(($cpu_memory_total+$cpu_memory))
    #`echo "$max_cpu_memory < $cpu_memory"|bc`
    echo $cpu_memory_total
    echo $cpu_memory
    cpu_memory_total=$(echo "scale=8; $cpu_memory_total+$cpu_memory" | bc)
    #cpu_usage_total=$(($cpu_usage_total+$cpu_usage))
    #echo "scale=2; $cpu_usage_total+$cpu_usage"



    if (($count==20)) 
        then
	    gpu_memory_mean=$(($gpu_memory_total/$count))
	    #cpu_memory_mean=$(($cpu_memory_total/$count))
	    #cpu_usage_mean=$(($cpu_usage_total/$count))
	    cpu_memory_mean=$(echo "scale=8; $cpu_memory_total/$count" |bc)
	  

	    gpu_memory_total=$((0))
	    cpu_memory_total=$((0))
	   
	    count=$((0))
	    echo "gpu memory mean:"$gpu_memory_mean
	    echo "CPU memory mean:"$cpu_memory_mean
	    
            current_time=$(date "+%s")

	    #echo $gpu_memory_mean","$cpu_memory_mean","$cpu_usage_mean","$cpu_time >>$log_file_name
	    echo $gpu_memory_mean","$cpu_memory_mean","$max_gpu_memory","$max_cpu_memory","$current_time >>$log_file_name

	    if [ `echo "$max_all_cpu_memory < $max_cpu_memory"|bc` -eq 1 ] ; then
                max_all_cpu_memory=$max_cpu_memory
            else
                echo "$max_all_cpu_memory > $max_cpu_memory "
            fi

            if [ `echo "$max_all_gpu_memory < $max_gpu_memory"|bc` -eq 1 ] ; then
                max_all_gpu_memory=$max_gpu_memory
            else
                echo "$max_all_gpu_memory > $max_gpu_memory "
            fi

            if [ `echo "$min_all_cpu_memory > $max_cpu_memory"|bc` -eq 1 ] ; then
                min_all_cpu_memory=$max_cpu_memory
            else
                echo "$min_all_cpu_memory < $max_cpu_memory "
            fi

            if [ `echo "$min_all_gpu_memory > $max_gpu_memory"|bc` -eq 1 ] ; then
                min_all_gpu_memory=$max_gpu_memory
            else
                echo "$min_all_gpu_memory > $max_gpu_memory "
            fi

            count_allmax=$(($count_allmax+1))
            mean_all_cpu_memory=$(echo "scale=8; $mean_all_cpu_memory+$max_cpu_memory" | bc)
            mean_all_gpu_memory=$(echo "scale=8; $mean_all_gpu_memory+$max_gpu_memory" | bc)

	    count_listening=$(($count_listening+1))
	    current_mean_listening_gpu_memory=$(echo "scale=8; $current_mean_listening_gpu_memory+$gpu_memory_mean" |bc)
	    if (($count_listening==5))
	        then
		    current_mean_listening_gpu_memory=$(echo "scale=8; $current_mean_listening_gpu_memory/$count_listening" |bc)
		    current_mean_all_gpu_memory=$(echo "scale=8; $mean_all_gpu_memory/$count_allmax" |bc)
	            current_mean_all_gpu_memory=$(echo "scale=8; $current_mean_all_gpu_memory/5" |bc)
		    if [ `echo "$current_mean_listening_gpu_memory < 600"|bc` -eq 1 ] ; then
                        listening=$((0))
                    else
                        echo "$gpu_memory_mean > $min_all_gpu_memory_2"
                    fi
		    count_listening=$((0))
	    fi
    fi


done

sleep 0.1
end_runningtime=$(date "+%s")
#total_runningtime="expr $end_runningtime - $start_runningtime"
total_runningtime=$(($end_runningtime-$start_runningtime))
#echo $total_runningtime

mean_all_cpu_memory=$(echo "scale=8; $mean_all_cpu_memory/$count_allmax" |bc)
mean_all_gpu_memory=$(echo "scale=8; $mean_all_gpu_memory/$count_allmax" |bc)

echo "MaxGPUUsage(MB),MaxMemoryusage(MB),MeanGPUUsage(MB), MeanMemoryusage(MB),MinGPUUsage(MB),MinMemoryusage(MB), TotalRunningTime(s)">>$log_file_name
echo $max_all_gpu_memory","$max_all_cpu_memory","$mean_all_gpu_memory","$mean_all_cpu_memory","$min_all_gpu_memory","$min_all_cpu_memory","$total_runningtime >>$log_file_name
