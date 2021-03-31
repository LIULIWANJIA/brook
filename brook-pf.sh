#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Brook
#	Version: 1.0.6
#	Author: Toyo
#	Blog: https://doub.io/wlzy-jc37/
#=================================================

sh_ver="1.0.6"
filepath=$(cd "$(dirname "$0")"; pwd)
file_1=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
file="/usr/local/brook-pf"
brook_file="/usr/local/brook-pf/brook"
brook_conf="/usr/local/brook-pf/brook.conf"
brook_log="/usr/local/brook-pf/brook.log"
Crontab_file="/usr/bin/crontab"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}
#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
check_installed_status(){
	[[ ! -e ${brook_file} ]] && echo -e "${Error} PTP_Server 没有安装，请检查 !" && exit 1
}
check_crontab_installed_status(){
	if [[ ! -e ${Crontab_file} ]]; then
		echo -e "${Error} Crontab 没有安装，开始安装..."
		if [[ ${release} == "centos" ]]; then
			yum install crond -y
		else
			apt-get install cron -y
		fi
		if [[ ! -e ${Crontab_file} ]]; then
			echo -e "${Error} Crontab 安装失败，请检查！" && exit 1
		else
			echo -e "${Info} Crontab 安装成功！"
		fi
	fi
}
check_pid(){
	PID=$(ps -ef| grep "brook relays"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}')
}
Download_brook(){
	[[ ! -e ${file} ]] && mkdir ${file}
	cd ${file}
    wget --no-check-certificate -N "https://raw.githubusercontent.com/LIULIWANJIA/brook/main/res/brook"
	chmod +x brook
}
Service_brook(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/LIULIWANJIA/brook/main/res/brook-pf_centos -O /etc/init.d/brook-pf; then
			echo -e "${Error} PTP_Server 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/brook-pf
		chkconfig --add brook-pf
		chkconfig brook-pf on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/LIULIWANJIA/brook/main/res/brook-pf_debian -O /etc/init.d/brook-pf; then
			echo -e "${Error} PTP_Server 管理脚本下载失败 !" && exit 1
		fi
		chmod +x /etc/init.d/brook-pf
		update-rc.d -f brook-pf defaults
	fi
	echo -e "${Info} PTP_Server 管理脚本下载完成 !"
}
Installation_dependency(){
	\cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}
check_port(){
	check_port_1=$1
	user_all=$(cat ${brook_conf}|sed '1d;/^\s*$/d')
	#[[ -z "${user_all}" ]] && echo -e "${Error} Brook 配置文件中用户配置为空 !" && exit 1
	check_port_statu=$(echo "${user_all}"|awk '{print $1}'|grep -w "${check_port_1}")
	if [[ ! -z "${check_port_statu}" ]]; then
		return 0
	else
		return 1
	fi
}
list_port(){
	port_Type=$1
	user_all=$(cat ${brook_conf}|sed '/^\s*$/d')
	if [[ -z "${user_all}" ]]; then
		if [[ "${port_Type}" == "ADD" ]]; then
			echo -e "${Info} 目前 PTP_Server 配置文件中用户配置为空。"
		else
			echo -e "${Info} 目前 PTP_Server 配置文件中用户配置为空。" && exit 1
		fi
	else
		user_num=$(echo -e "${user_all}"|wc -l)
		for((integer = 1; integer <= ${user_num}; integer++))
		do
			user_port=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $1}')
			user_ip_pf=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $2}')
			user_port_pf=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $3}')
			user_Enabled_pf=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $4}')
			if [[ ${user_Enabled_pf} == "0" ]]; then
				user_Enabled_pf_1="${Red_font_prefix}禁用${Font_color_suffix}"
			else
				user_Enabled_pf_1="${Green_font_prefix}启用${Font_color_suffix}"
			fi
			user_list_all=${user_list_all}"本机端口: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t PTP_IP: ${Green_font_prefix}"${user_ip_pf}"${Font_color_suffix}\t PTP_Port: ${Green_font_prefix}"${user_port_pf}"${Font_color_suffix}\t 状态: ${user_Enabled_pf_1}\n"
			user_IP=""
		done
		ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
		if [[ -z "${ip}" ]]; then
			ip=$(wget -qO- -t1 -T2 api.ip.sb/ip)
			if [[ -z "${ip}" ]]; then
				ip=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
				if [[ -z "${ip}" ]]; then
					ip="VPS_IP"
				fi
			fi
		fi
		echo -e "当前PTP_Server总数: ${Green_background_prefix} "${user_num}" ${Font_color_suffix} 本机IP: ${Green_background_prefix} "${ip}" ${Font_color_suffix}"
		echo -e "${user_list_all}"
		echo -e "========================\n"
	fi
}
Install_brook(){
	check_root
	[[ -e ${brook_file} ]] && echo -e "${Error} 检测到 PTP_Server 已安装 !" && exit 1
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	echo -e "${Info} 开始下载/安装..."
	Download_brook
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_brook
	echo -e "${Info} 开始写入 配置文件..."
	echo "" > ${brook_conf}
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} PTP_Server 安装完成。"
	echo -e "${Info} 修改配置文件：/usr/local/brook-pf/brook.conf "
	echo -e "${Info} 一行一个(首尾各空出一行) 格式 本机端口 被转发IP 被转发端口 状态(1/0 1开启 0关闭)"
	echo -e "${Info} 例   22122 139.139.139.139 22 1"
	echo -e "${Info} 例   完事保存，重启脚本开启服务即可2333"
}
Start_brook(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} PTP_Server 正在运行，请检查 !" && exit 1
	/etc/init.d/brook-pf start
}
Stop_brook(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} PTP_Server 没有运行，请检查 !" && exit 1
	/etc/init.d/brook-pf stop
}
Restart_brook(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/brook-pf stop
	/etc/init.d/brook-pf start
}
Uninstall_brook(){
	check_installed_status
	echo -e "确定要卸载 PTP_Server ? [y/N]\n"
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		if [[ -e ${brook_conf} ]]; then
			user_all=$(cat ${brook_conf}|sed '/^\s*$/d')
			user_all_num=$(echo "${user_all}"|wc -l)
			if [[ ! -z ${user_all} ]]; then
				for((integer = 1; integer <= ${user_all_num}; integer++))
				do
					port=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $1}')
					Del_iptables
				done
				Save_iptables
			fi
		fi
		if [[ ! -z $(crontab -l | grep "brook-pf.sh monitor") ]]; then
			crontab_monitor_brook_cron_stop
		fi
		rm -rf ${file}
		if [[ ${release} = "centos" ]]; then
			chkconfig --del brook-pf
		else
			update-rc.d -f brook-pf remove
		fi
		rm -rf /etc/init.d/brook-pf
		echo && echo "PTP_Server 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
View_Log(){
	check_installed_status
	[[ ! -e ${brook_log} ]] && echo -e "${Error} PTP_Server 日志文件不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志(正常情况是没有使用日志记录的)" && echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${brook_log}${Font_color_suffix} 命令。" && echo
	tail -f ${brook_log}
}
Set_crontab_monitor_brook(){
	check_installed_status
	check_crontab_installed_status
	crontab_monitor_brook_status=$(crontab -l|grep "brook-pf.sh monitor")
	if [[ -z "${crontab_monitor_brook_status}" ]]; then
		echo && echo -e "当前监控模式: ${Green_font_prefix}未开启${Font_color_suffix}" && echo
		echo -e "确定要开启 ${Green_font_prefix}PTP_Server 运行状态监控${Font_color_suffix} 功能吗？(当进程关闭则自动启动 PTP_Server)[Y/n]"
		read -e -p "(默认: y):" crontab_monitor_brook_status_ny
		[[ -z "${crontab_monitor_brook_status_ny}" ]] && crontab_monitor_brook_status_ny="y"
		if [[ ${crontab_monitor_brook_status_ny} == [Yy] ]]; then
			crontab_monitor_brook_cron_start
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo && echo -e "当前监控模式: ${Green_font_prefix}已开启${Font_color_suffix}" && echo
		echo -e "确定要关闭 ${Green_font_prefix}PTP_Server 运行状态监控${Font_color_suffix} 功能吗？(当进程关闭则自动启动 PTP_Server)[y/N]"
		read -e -p "(默认: n):" crontab_monitor_brook_status_ny
		[[ -z "${crontab_monitor_brook_status_ny}" ]] && crontab_monitor_brook_status_ny="n"
		if [[ ${crontab_monitor_brook_status_ny} == [Yy] ]]; then
			crontab_monitor_brook_cron_stop
		else
			echo && echo "	已取消..." && echo
		fi
	fi
}
crontab_monitor_brook_cron_start(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/brook-pf.sh monitor/d" "$file_1/crontab.bak"
	echo -e "\n* * * * * /bin/bash $file_1/brook-pf.sh monitor" >> "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "brook-pf.sh monitor")
	if [[ -z ${cron_config} ]]; then
		echo -e "${Error} PTP_Server 运行状态监控功能 启动失败 !" && exit 1
	else
		echo -e "${Info} PTP_Server 运行状态监控功能 启动成功 !"
	fi
}
crontab_monitor_brook_cron_stop(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/brook-pf.sh monitor/d" "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "brook-pf.sh monitor")
	if [[ ! -z ${cron_config} ]]; then
		echo -e "${Error} PTP_Server 运行状态监控功能 停止失败 !" && exit 1
	else
		echo -e "${Info} PTP_Server 运行状态监控功能 停止成功 !"
	fi
}
crontab_monitor_brook(){
	check_installed_status
	check_pid
	echo "${PID}"
	if [[ -z ${PID} ]]; then
		echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] 检测到 PTP_Server 未运行 , 开始启动..." | tee -a ${brook_log}
		/etc/init.d/brook-pf start
		sleep 1s
		check_pid
		if [[ -z ${PID} ]]; then
			echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] PTP_Server 启动失败..." | tee -a ${brook_log}
		else
			echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] PTP_Server 启动成功..." | tee -a ${brook_log}
		fi
	else
		echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] PTP_Server 进程运行正常..." | tee -a ${brook_log}
	fi
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${bk_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${bk_port} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
	else
		iptables-save > /etc/iptables.up.rules
	fi
}
Set_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		chkconfig --level 2345 iptables on
	else
		iptables-save > /etc/iptables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
check_sys
action=$1
if [[ "${action}" == "monitor" ]]; then
	crontab_monitor_brook
else
	echo && echo -e "  PTP Server 一键管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ---- liuliwanjia.top/nv ----
  
————————————————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 PTP_Server
 ${Green_font_prefix} 2.${Font_color_suffix} 启动 PTP_Server
 ${Green_font_prefix} 3.${Font_color_suffix} 重启 PTP_Server
————————————————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 停止 PTP_Server
 ${Green_font_prefix} 5.${Font_color_suffix} 卸载 PTP_Server
————————————————————————
 ${Green_font_prefix} 6.${Font_color_suffix} 查看 PTP_Server 端口转发
 ${Green_font_prefix} 7.${Font_color_suffix} 查看 PTP_Server 日志
 ${Green_font_prefix} 8.${Font_color_suffix} 监控 PTP_Server 运行状态
————————————————————————" && echo
if [[ -e ${brook_file} ]]; then
	check_pid
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
fi
echo
read -e -p " 请输入数字 [0-10]:" num
case "$num" in
	1)
	Install_brook
	;;
	2)
	Start_brook
	;;
	3)
	Restart_brook
	;;
	4)
	Stop_brook
	;;
	5)
	Uninstall_brook
	;;
	6)
	check_installed_status
	list_port
	;;
	7)
	View_Log
	;;
	8)
	Set_crontab_monitor_brook
	;;
	*)
	echo "请输入正确数字 [0-8]"
	;;
esac
fi
