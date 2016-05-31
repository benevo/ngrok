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
    if [ ! -f "$1" ]; then
        echo -e "${str_info} conf file $1 not existed!"
        return 0
    fi
    
    cat $1 | while read line
    do
        echo "File: ${line}"
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
    #sed '/^'$pid_apache_found'/d' ${basepath}/.apache.db > .apache.db   # 删除记录
    echo -e "${str_info} Apache server for directory: \033[36m "${apache_instance_dir}" \033[0m   on port $1  stopped."
}

function fun_local_apache_stop_all(){
    pid_list=`ps aux | grep "python -m SimpleHTTPServer" | grep -v "grep" | awk '{print $2}'`
    
    if [ -z "$pid_list" ]; then
        return 0
    fi
    
    kill -9 $pid_list
    #sed '/^'$pid_apache_found'/d' ${basepath}/.apache.db > .apache.db  # 删除记录
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

function fun_get_ngrok_pid(){
    pid_ngrok=`ps aux | grep "ngrok -config" | grep -v "grep" | awk '{print $2}'`
    pid_ngrok_count=`ps aux | grep "ngrok -config" | grep -v "grep" | awk '{print $2}' | wc -l`
}

function fun_ngrok_start(){
    fun_get_ngrok_pid
    
    # ngrok server
    cfg=`cd ${basepath}/../; pwd`
    if [ $pid_ngrok_count -eq 0 ]; then
        cd ${basepath}
        #nohup ./ngrok -config=../ngrok.cfg start-all &> ngrok.log &
        ./ngrok -config=../ngrok.cfg start-all &> ngrok.log
        pid=`ps aux | grep "ngrok -config" | grep -v "grep" | awk '{print $2}'`
        echo -e "Ngrok server for: \033[45;37m ${cfg}/ngrok.cfg \033[0m   started witch pid: ${pid}."
    else
        echo -e "Ngrok server for: \033[45;37m  ${cfg}/ngrok.cfg \033[0m   already started witch pid: ${pid_ngrok}."
    fi
}

function fun_ngrok_stop(){
    fun_get_ngrok_pid
    if [ $pid_ngrok_count -gt 0 ]; then
        kill -9 $pid_ngrok
    fi
    echo -e "Ngrok server for: \033[45;37m  ${cfg}/ngrok.cfg \033[0m   stopped."
}

function fun_ngrok_restart(){
    fun_ngrok_stop
    fun_ngrok_start
    echo -e "Ngrok server for: \033[45;37m  ${cfg}/ngrok.cfg \033[0m   restarted."
}

# main
clear
action=$1
[  -z $1 ]
case "$action" in
    start)
        rm -f ${apache}/apache.log
        fun_local_apache_start "default" "8000" 2>&1 | tee ${apache}/apache.log
        rm -f ${basepath}/ngrok.log
        fun_ngrok_start 2>&1 | tee ${basepath}/ngrok.log
    ;;
    stop)
        fun_local_apache_stop "8000"
        fun_ngrok_stop
    ;;
    restart)
        fun_local_apache_restart
        fun_ngrok_restart
    ;;
    *)
        echo "Arguments error! [${action} ]"
        echo "Usage: `basename $0` [ start | stop | restart ]"
    ;;
esac
