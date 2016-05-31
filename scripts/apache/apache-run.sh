#!/bin/bash

basepath=$(cd `dirname $0`; pwd)
str_info="\033[45;37m INFO \033[0m "
str_err="\033[41;37m ERROR: \033[0m "

function fun_get_local_apache_list(){
    list=`ps aux | grep "python -m SimpleHTTPServer" | grep -v "grep" | awk '{print $2, "\t"$NF, "\t"$1}' | wc -l`
    if [ "$list" -gt 0 ]; then
        echo -e "\033[33mPID\tPORT\tUSER\tDirectory \033[0m"
        echo "----------------------------------"
        ps aux | grep "python -m SimpleHTTPServer" | grep -v "grep" | awk '{print $2, "\t"$NF, "\t"$1}'
    fi
}

function fun_local_apache_start(){
    # web server for local directory ${apache_instance_dir}
    port_apache_new="8000"
    dir_tmp=$1
    if [ "$1" == "default" ]; then
        dir_tmp=${apache}
    fi
    if [ -d "$dir_tmp" ]; then
        apache_instance_dir="$dir_tmp"
        if [ "$dir_tmp" == "." ]; then
            apache_instance_dir=${basepath}
        fi
    else
        echo "The directory for ($dir_tmp) is invalid!"
        return 0
    fi
    if [ -n "$2" ]; then
        port_apache_new="$2"
    fi
    
    fun_get_pid_for_port $port_apache_new
    
    
    if [ -n "${apache_instance_dir}" ] && [ -n "${appache_new_port}"]; then
        count_instance_on_port=`ps aux | grep "python -m SimpleHTTPServer ${port_apache_new}" | grep -v "grep" | awk '{print $2}' | wc -l`
        if [ $count_instance_on_port -eq 0 ]; then
            cd ${apache_instance_dir}
            nohup python -m SimpleHTTPServer ${port_apache_new} &> apache.log &
            fun_get_pid_for_port $port_apache_new
            echo -e "${str_info} Apache server for directory: \033[36m "${apache_instance_dir}" \033[0m  \033[32m started: \033[0m"
            echo -e "\tPort: \033[36m ${port_apache_new} \033[0m"
            echo -e "\tPID: \033[36m ${pid_apache_found} \033[0m"
            ps aux | grep "python -m SimpleHTTPServer" | grep -v "grep" | awk '{print $2, "\t"$1, "\t"$NF, "'${apache_instance_dir}'"}' >> ${basepath}/.apache.db
        else
            echo -e "${str_err} Apache server for directory: \033[36m "${apache_instance_dir}" \033[0m  already started:"
        fi
    fi
}

function fun_local_apache_startf(){
    # web server for local directory ${apache_instance_dir}
    conf_filepath=$1
    if [ -z "$1" ]; then
        conf_filepath=$(cd ~; pwd)/.apache.conf
    fi

    if [ ! -f "${conf_filepath}" ]; then
        echo -e "${str_info} conf file ${conf_filepath} not existed!"
        return 0
    fi
    
    cat ${conf_filepath} | while read line
    do
        if [ -n "${line}" ]; then
            fun_local_apache_start ${line}
        fi
    done
}

function fun_get_pid_for_port(){
    pid_apache_found=""
    if [ -n "$1" ]; then
        pid_apache_found=`ps aux | grep "python -m SimpleHTTPServer $1"  | grep -v "grep" | awk '{print $2}'`
    fi
}

function fun_local_apache_stop(){
    pid_apache_found=""
    if [ -n "$1" ]; then
        fun_get_pid_for_port "$1"
    fi
    
    if [ -z "$pid_apache_found" ]; then
        echo -e "No apache server on port: $1"
        return 0
    fi
    
    kill -9 $pid_apache_found
    sed '/^'$pid_apache_found'/d' ${basepath}/.apache.db > .apache.db	# 删除记录
    echo -e "${str_info} Apache server for directory: \033[36m "${apache_instance_dir}" \033[0m   on port $1  stopped."
}

function fun_local_apache_stop_all(){
    pid_list=`ps aux | grep "python -m SimpleHTTPServer" | grep -v "grep" | awk '{print $2}'`
    
    if [ -z "$pid_list" ]; then
        return 0
    fi
    
    kill -9 $pid_list
    #sed '/^'$pid_apache_found'/d' ${basepath}/.apache.db > .apache.db	# 删除记录
    echo -e "${str_info} Apache servers All stopped."
}

function fun_local_apache_restart(){
    fun_local_apache_stop
    fun_local_apache_start
    echo -e "Apache server for directory: \033[45;37m "${apache_instance_dir}" \033[0m   restarted."
}

function fun_get_apache_dir(){
    if [ -n "$1" ]; then
        if [ -n "$2" ]; then
            port_apache_new="$2"
            apache="$1"
        else
            port_apache_new="8000"
        fi
    else
        port_apache_new="8000"
    fi
}

# main

#clear
action=$1
[  -z $1 ]
case "$action" in
    start) # sh apache-run.sh start /root/document 8290
        rm -f ${apache_instance_dir}/apache.log
        fun_get_apache_dir "$2" "$3"
        fun_local_apache_start $apache $port_apache_new 2>&1 #| tee ${apache_instance_dir}/apache.log
    ;;
    startf) # sh apache-run.sh startf /path/for/cfgfile
        rm -f ${apache_instance_dir}/apache.log
        fun_local_apache_startf "$2" 2>&1 #| tee ${apache_instance_dir}/apache.log
    ;;
    stop)
        fun_local_apache_stop "$2"
    ;;
    stop-all)
        fun_local_apache_stop_all "$2"
    ;;
    restart)
        fun_local_apache_restart
    ;;
    list)
        fun_get_local_apache_list
    ;;
    *)
        echo "Arguments error! [${action} ]"
        echo "Usage: `basename $0` [ start | startf | stop | stop-all | restart | list]"
    ;;
esac
