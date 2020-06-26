#!/bin/bash
BuildTime=20200626
# 专家模式开关
# 注意： 只有当你了解整个AliDDNS工作流程，并且有一定的动手能力，希望对AliDDNS脚本的更多参数进行
#       深度定制时，你可以打开这个开关，会提供更多可以设置的选项，但如果你不懂、超级小白，请不要
#       打开这个开关！因打开专家模式后配置失误发生的问题，作者不负任何责任！
#       如需打开专家模式，请将脚本文件中的 Switch_AliDDNS_ExpertMode 变量值设置为1，即可打开
#       专家模式，如需关闭，请将此值设置为0！
Switch_AliDDNS_ExpertMode=0

# ===================================================================================
#
# 下面的代码均为程序的核心代码，不要改动任何地方的代码，直接运行脚本即可使用！
#
# ===================================================================================

# Shell环境初始化
# 字体颜色定义
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"
# 消息提示定义
Msg_Info="${Font_Blue}[Info] ${Font_Suffix}"
Msg_Warning="${Font_Yellow}[Warning] ${Font_Suffix}"
Msg_Error="${Font_Red}[Error] ${Font_Suffix}"
Msg_Success="${Font_Green}[Success] ${Font_Suffix}"
Msg_Fail="${Font_Red}[Failed] ${Font_Suffix}"
# Shell变量开关初始化
Switch_env_curl_exist=0
Switch_env_openssl_exist=0
Switch_env_nslookup_exist=0
Switch_env_jq_exist=0

# Shell脚本信息显示
echo -e "${Font_Green}
#=========================================================
# AliDDNS 工具 (阿里云云解析修改工具)
#
# Build:    $BuildTime
# 支持平台: CentOS/Debian/Ubuntu
# 作者:     Small_5 (基于iLemonrain的AliDDNS改进)
#=========================================================

${Font_suffix}"

# 检查Root权限，并配置开关
function_Check_Root(){
	if [ "`id -u`" != 0 ];then
		Switch_env_is_root=0
		Config_configdir="$(cd ~;echo $PWD)/OneKeyAliDDNS"
	else
		Switch_env_is_root=1
		Config_configdir="/etc/OneKeyAliDDNS"
	fi
}

function_Check_Enviroment(){
	command -v curl >/dev/null 2>&1 && Switch_env_curl_exist=1
	command -v openssl >/dev/null 2>&1 && Switch_env_openssl_exist=1
	command -v nslookup >/dev/null 2>&1 && Switch_env_nslookup_exist=1
	command -v jq >/dev/null 2>&1 && Switch_env_jq_exist=1
	if [ -f "/etc/redhat-release" ];then
		Switch_env_system_release=centos
	elif [ -f "/etc/lsb-release" ];then
		Switch_env_system_release=ubuntu
	elif [ -f "/etc/debian_version" ];then
		Switch_env_system_release=debian
	else
		Switch_env_system_release=unknown
	fi
}

function_Install_Enviroment(){
	if [ "$Switch_env_curl_exist" = 0 ] || [ "$Switch_env_openssl_exist" = 0 ] || [ "$Switch_env_nslookup_exist" = 0 ] || [ "$Switch_env_jq_exist" = 0 ];then
		echo -e "${Msg_Warning}未检查到必需组件或者组件不完整，正在尝试安装……"
		if [ "$Switch_env_is_root" = 1 ];then
			if [ "$Switch_env_system_release" = centos ];then
				echo -e "${Msg_Info}检测到系统分支：CentOS"
				echo -e "${Msg_Info}正在安装必需组件……"
				yum install curl openssl bind-utils jq -y
			elif [ "$Switch_env_system_release" = ubuntu ];then
				echo -e "${Msg_Info}检测到系统分支：Ubuntu"
				echo -e "${Msg_Info}正在安装必需组件……"
				apt-get install curl openssl dnsutils jq -y
			elif [ "$Switch_env_system_release" = debian ];then
				echo -e "${Msg_Info}检测到系统分支：Debian"
				echo -e "${Msg_Info}正在安装必需组件……"
				apt-get install curl openssl dnsutils jq -y
			else
				echo -e "${Msg_Warning}系统分支未知，取消环境安装，建议手动安装环境！"
				exit 1
			fi
		elif command -v sudo >/dev/null 2>&1;then
			echo -e "${Msg_Warning}检测到当前脚本并非以root权限启动，正在尝试通过sudo命令安装……"
			if [ "$Switch_env_system_release" = centos ];then
				echo -e "${Msg_Info}检测到系统分支：CentOS"
				echo -e "${Msg_Info}正在安装必需组件 (使用sudo)……"
				sudo yum install curl openssl bind-utils jq -y
			elif [ "$Switch_env_system_release" = ubuntu ];then
				echo -e "${Msg_Info}检测到系统分支：Ubuntu"
				echo -e "${Msg_Info}正在安装必需组件 (使用sudo)……"
				sudo apt-get install curl openssl dnsutils jq -y
			elif [ "$Switch_env_system_release" = debian ];then
				echo -e "${Msg_Info}检测到系统分支：Debian"
				echo -e "${Msg_Info}正在安装必需组件 (使用sudo)……"
				sudo apt-get install curl openssl dnsutils jq -y
			else
				echo -e "${Msg_Warning}系统分支未知，取消环境安装，建议手动安装环境！"
				exit 1
			fi
		else
			echo -e "${Msg_Error}系统缺少必需环境，并且无法自动安装，建议手动安装！"
			exit 1
		fi
		if ! command -v curl >/dev/null 2>&1;then
			echo -e "${Msg_Error}curl组件安装失败！会影响到程序运行！建议手动安装！"
			exit 1
		fi
		if ! command -v openssl >/dev/null 2>&1;then
			echo -e "${Msg_Error}openssl组件安装失败！会影响到程序运行！建议手动安装！"
			exit 1
		fi
		if ! command -v nslookup >/dev/null 2>&1;then
			echo -e "${Msg_Error}nslookup组件安装失败！会影响到程序运行！建议手动安装！"
			exit 1
		fi
		if ! command -v jq >/dev/null 2>&1;then
			echo -e "${Msg_Error}jq组件安装失败！会影响到程序运行！建议手动安装！"
			exit 1
		fi
	fi
}

# 判断是否有已存在的配置文件 (是否已经配置过环境)
function_AliDDNS_CheckConfig(){
	if [ -f $Config_configdir/config.cfg ];then
		echo -e "${Msg_Info}检测到存在的配置，自动读取现有配置\n       如果你不需要，请通过菜单中的清理环境选项进行清除"
		# 读取配置文件
		__Domain=`sed '/^Domain=/!d;s/.*=//' $Config_configdir/config.cfg | sed 's/\"//g'`
		__ID=`sed '/^AliDDNS_AK=/!d;s/.*=//' $Config_configdir/config.cfg | sed 's/\"//g'`
		__KEY=`sed '/^AliDDNS_SK=/!d;s/.*=//' $Config_configdir/config.cfg | sed 's/\"//g'`
		__TTL=`sed '/^TTL=/!d;s/.*=//' $Config_configdir/config.cfg | sed 's/\"//g'`
		__TYPE=`sed '/^TYPE=/!d;s/.*=//' $Config_configdir/config.cfg | sed 's/\"//g'`
		__Local_IP_BIN=`sed '/^Local_IP=/!d;s/.*=//' $Config_configdir/config.cfg | sed 's/\"//g'`
		__DNS=`sed '/^DNS=/!d;s/.*=//' $Config_configdir/config.cfg | sed 's/\"//g'`
		retry_count=`sed '/^retry_count=/!d;s/.*=//' $Config_configdir/config.cfg | sed 's/\"//g'`
		retry_seconds=`sed '/^retry_seconds=/!d;s/.*=//' $Config_configdir/config.cfg | sed 's/\"//g'`
		if [ -z "$__Domain" ] || [ -z "$__ID" ] || [ -z "$__KEY" ] || [ -z "$__TTL" ] || [ -z "$__TYPE" ] || [ -z "$__Local_IP_BIN" ] || [ -z "$__DNS" ] || [ -z "$retry_count" ] || [ -z "$retry_seconds" ];then
			echo -e "${Msg_Error}配置文件有误，请检查配置文件，或者建议清理环境后重新配置 !"
			exit 1
		fi
		# 从 $__Domain 分离主机和域名
		[ "${__Domain:0:2}" = "@." ] && __Domain="${__Domain/./}" # 主域名处理
		[ "$__Domain" = "${__Domain/@/}" ] && __Domain="${__Domain/./@}" # 未找到分隔符，兼容常用域名格式
		__HOST="${__Domain%%@*}"
		__DOMAIN="${__Domain#*@}"
		[ -z "$__HOST" -o "$__HOST" = "$__DOMAIN" ] && __HOST=@
		Switch_AliDDNS_Config_Exist=1
	else
		Switch_AliDDNS_Config_Exist=0
	fi
}

function_AliDDNS_SetConfig(){
	# Domain
	echo -e "\n${Msg_Info}请输入域名 (比如 www.example.com)，如果需要更新主域名，请输入@，例如@.example.com"
	read -p "(此项必须填写，查看帮助请输入h):" __Domain
	while [ -z "$__Domain" -o "$__Domain" = h ];do
		[ "$__Domain" = h ] && function_document_AliDDNS_Domain
		[ -z "$__Domain" ] && echo -e "${Msg_Error}此项不可为空，请重新填写"
		echo -e "${Msg_Info}请输入域名 (比如 www.example.com)，如果需要更新主域名，请输入@，例如@.example.com"
		read -p "(此项必须填写，查看帮助请输入h):" __Domain
	done
	# ID
	echo -e "\n${Msg_Info}请输入阿里云AccessKey ID"
	read -p "(此项必须填写，查看帮助请输入h):" __ID
	while [ -z "$__ID" -o "$__ID" = h ];do
		[ "$__ID" = h ] && function_document_AliDDNS_ID
		[ -z "$__ID" ] && echo -e "${Msg_Error}此项不可为空，请重新填写"
		echo -e "${Msg_Info}请输入阿里云AccessKey ID"
		read -p "(此项必须填写，查看帮助请输入h):" __ID
	done
	# KEY
	echo -e "\n${Msg_Info}请输入阿里云AccessKey Secret"
	read -p "(此项必须填写，查看帮助请输入h):" __KEY
	while [ -z "$__KEY" -o "$__KEY" = h ];do
		[ "$__KEY" = h ] && function_document_AliDDNS_KEY
		[ -z "$__KEY" ] && echo -e "${Msg_Error}此项不可为空，请重新填写"
		echo -e "${Msg_Info}请输入阿里云AccessKey Secret"
		read -p "(此项必须填写，查看帮助请输入h):" __KEY
	done
	# TTL
	echo -e "\n${Msg_Info}请输入记录的TTL(Time-To-Live)值："
	read -p "(默认为600，查看帮助请输入h):" __TTL
	while [ -n "$__TTL" ] && [ -z "$(echo $__TTL| sed -n "/^[0-9]\+$/p")" ];do
		[ "$__TTL" = h ] && function_document_AliDDNS_TTL
		[ "$__TTL" != h ] && echo -e "${Msg_Error}此项只能为数字，字母或者符号无效："
		echo -e "${Msg_Info}请输入记录的TTL(Time-To-Live)值："
		read -p "(默认为600，查看帮助请输入h):" __TTL
	done
	[ -z "$__TTL" ] && echo -e "${Msg_Info}检测到输入空值，设置__TTL值为：600" && __TTL="600"
	# TYPE
	echo -e "\n${Msg_Info}请输入域名类型(A/AAAA)："
	read -p "(默认为A，查看帮助请输入h):" __TYPE
	while [ -n "$__TYPE" ] && [ "$__TYPE" != A -a "$__TYPE" != AAAA ];do
		[ "$__TYPE" = h ] && function_document_AliDDNS_TYPE
		[ "$__TYPE" != h ] && echo -e "${Msg_Error}填写错误，请重新填写"
		echo -e "${Msg_Info}请输入域名类型(A/AAAA)："
		read -p "(默认为A，查看帮助请输入h):" __TYPE
	done
	[ -z "$__TYPE" ] && echo -e "${Msg_Info}检测到输入空值，设置类型为：A" && __TYPE=A
	# Local_IP
	if [ "$Switch_AliDDNS_ExpertMode" = 1 ];then
		echo -e "\n${Msg_Info}请输入获取本机IP使用的命令"
		read -p "(查看帮助请输入h):" __Local_IP_BIN
		while [ "$__Local_IP_BIN" = h ];do
			function_document_AliDDNS_LocalIP
			echo -e "${Msg_Info}请输入获取本机IP使用的命令"
			read -p "(查看帮助请输入h):" __Local_IP_BIN
		done
		if [ -z "$__Local_IP_BIN" ];then
			if [ "$__TYPE" = A ];then
				__Local_IP_BIN=A
			else
				__Local_IP_BIN=B
			fi
			echo -e "${Msg_Info}检测到输入空值，设置为默认命令"
		fi
	else
		if [ "$__TYPE" = A ];then
			__Local_IP_BIN=A
		else
			__Local_IP_BIN=B
		fi
	fi
	case "$__Local_IP_BIN" in
		A)
		__Local_IP_BIN="curl -s https://pv.sohu.com/cityjson";;
		B)
		__Local_IP_BIN="curl -s6 https://ipv6-test.com/api/myip.php";;
	esac
	# DNS
	if [ "$Switch_AliDDNS_ExpertMode" = 1 ];then
		echo -e "\n${Msg_Info}请输入解析使用的DNS服务器"
		read -p "(查看帮助请输入h):" __DNS
		while [ "$__DNS" = h ];do
			function_document_AliDDNS_DNS
			echo -e "${Msg_Info}请输入解析使用的DNS服务器"
			read -p "(查看帮助请输入h):" __DNS
		done
		[ -z "$__DNS" ] && echo -e "${Msg_Info}检测到输入空值，设置默认DNS服务器为：8.8.8.8" && __DNS="8.8.8.8"
	else
		__DNS="8.8.8.8"
	fi
	# 重试次数
	if [ "$Switch_AliDDNS_ExpertMode" = 1 ];then
		echo -e "\n${Msg_Info}错误重试次数(0为无限重试，默认为2，不推荐设置为0)"
		read -p "(请输入错误重试次数):" retry_count
		[ -z "$retry_count" ] && echo -e "${Msg_Info}检测到输入空值，设置为2" && retry_count=2
	else
		retry_count=2
	fi
	# 重试间隔
	if [ "$Switch_AliDDNS_ExpertMode" = 1 ];then
		echo -e "\n${Msg_Info}错误重试间隔时间(默认5秒)"
		read -p "(请输入错误重试间隔时间):" retry_seconds
		[ -z "$retry_seconds" ] && echo -e "${Msg_Info}检测到输入空值，设置为5" && retry_seconds=5
	else
		retry_seconds=5
	fi
}

function_AliDDNS_WriteConfig(){
	# 写入配置文件
	echo -e "\n${Msg_Info}正在写入配置文件……"
	mkdir -p $Config_configdir
	cat>$Config_configdir/config.cfg<<EOF
Domain="$__Domain"
AliDDNS_AK="$__ID"
AliDDNS_SK="$__KEY"
TTL="$__TTL"
TYPE="$__TYPE"
Local_IP="$__Local_IP_BIN"
DNS="$__DNS"
retry_count="$retry_count"
retry_seconds="$retry_seconds"
EOF
}

function_ServerChan_Configure(){
	echo -e "\n${Msg_Info}请输入ServerChan SCKEY："
	read -p "(此项必须填写):" ServerChan_SCKEY
	while [ -z "$ServerChan_SCKEY" ];do
		echo -e "${Msg_Error}此项不可为空，请重新填写"
		echo -e "${Msg_Info}请输入ServerChan SCKEY："
		read -p "(此项必须填写):" ServerChan_SCKEY
	done
	echo -e "\n${Msg_Info}请输入服务器名称：请使用中文/英文，不要使用除了英文下划线以外任何符号"
	read -p "(此项必须填写，便于识别):" ServerChan_ServerFriendlyName
	while [ -z "$ServerChan_ServerFriendlyName" ];do
		echo -e "${Msg_Error}此项不可为空，请重新填写"
		echo -e "${Msg_Info}请输入服务器名称：请使用中文/英文，不要使用除了英文下划线以外任何符号"
		read -p "(此项必须填写，便于识别):" ServerChan_ServerFriendlyName
	done
}

function_ServerChan_WriteConfig(){
	# 写入配置文件
	echo -e "\n${Msg_Info}正在写入配置文件……"
	mkdir -p $Config_configdir
	cat>$Config_configdir/config-ServerChan.cfg<<EOF
ServerChan_ServerFriendlyName="$ServerChan_ServerFriendlyName"
ServerChan_SCKEY="$ServerChan_SCKEY"
EOF
}

function_Telegram_Configure(){
	echo -e "\n${Msg_Info}请输入Telegram Bot URL："
	read -p "(此项必须填写，查看帮助请输入h):" Telegram_URL
	while [ -z "$Telegram_URL" -o "$Telegram_URL" = h ];do
		[ "$Telegram_URL" = h ] && function_document_Telegram_URL
		[ -z "$Telegram_URL" ] && echo -e "${Msg_Error}此项不可为空，请重新填写"
		echo -e "${Msg_Info}请输入Telegram Bot URL："
		read -p "(此项必须填写，查看帮助请输入h):" Telegram_URL
	done
	echo -e "\n${Msg_Info}请输入服务器名称：请使用中文/英文，不要使用除了英文下划线以外任何符号"
	read -p "(此项必须填写，便于识别):" Telegram_ServerFriendlyName
	while [ -z "$Telegram_ServerFriendlyName" ];do
		echo -e "${Msg_Error}此项不可为空，请重新填写"
		echo -e "${Msg_Info}请输入服务器名称：请使用中文/英文，不要使用除了英文下划线以外任何符号"
		read -p "(此项必须填写，便于识别):" Telegram_ServerFriendlyName
	done
}

function_Telegram_WriteConfig(){
	# 写入配置文件
	echo -e "\n${Msg_Info}正在写入配置文件……"
	mkdir -p $Config_configdir
	cat>$Config_configdir/config-Telegram.cfg<<EOF
Telegram_ServerFriendlyName="$Telegram_ServerFriendlyName"
Telegram_URL="$Telegram_URL"
EOF
}

# 帮助文档
function_document_AliDDNS_Domain(){
	echo -e "${Msg_Info}${Font_Green}Domain 说明
这个参数设置你的DDNS域名，当需要更新主域名IP的时候，使用例如@.example.com${Font_Suffix}"
}

function_document_AliDDNS_ID(){
	echo -e "${Msg_Info}${Font_Green}AliDDNS_AK 说明
这个参数决定修改DDNS记录所需要用到的阿里云API信息 (AccessKey ID)。
获取AccessKey ID和AccessKey Secret请移步：
https://usercenter.console.aliyun.com/#/manage/ak
${Font_Red}注意：请不要泄露你的AK/SK给任何人！
一旦他们获取了你的AK/SK，将会直接拥有控制你阿里云账号的能力！
为了您的阿里云账号安全，请不要随意分享AK/SK(包括请求帮助时候的截图)！${Font_Suffix}"
}

function_document_AliDDNS_KEY(){
	echo -e "${Msg_Info}${Font_Green}AliDDNS_SK 说明
这个参数决定修改DDNS记录所需要用到的阿里云API信息 (AccessKey Secret)。
获取AccessKey ID和AccessKey Secret请移步：
https://usercenter.console.aliyun.com/#/manage/ak
${Font_Red}注意：请不要泄露你的AK/SK给任何人！
一旦他们获取了你的AK/SK，将会直接拥有控制你阿里云账号的能力！
为了您的阿里云账号安全，请不要随意分享AK/SK(包括请求帮助时候的截图)！${Font_Suffix}"
}

function_document_AliDDNS_TTL(){
	echo -e "${Msg_Info}${Font_Green}__TTL 说明
这个参数决定你要修改的DDNS记录中，TTL(Time-To-Line)时长。
越短的TTL，DNS更新生效速度越快 (但也不是越快越好，因情况而定)
免费版产品可设置为 (600-86400) (即10分钟-1天)
收费版产品可根据所购买的云解析企业版产品配置设置为 (1-86400) (即1秒-1天)
${Font_Red}请免费版用户不要设置TTL低于600秒，会导致运行报错！${Font_Suffix}"
}

function_document_AliDDNS_TYPE(){
	echo -e "${Msg_Info}${Font_Green}TYPE 说明
这个参数决定你要的域名使用A记录还是AAAA记录
A记录为IPv4,AAAA记录为IPv6${Font_Suffix}"
}

function_document_AliDDNS_LocalIP(){
	echo -e "${Msg_Info}${Font_Green}LocalIP 说明
这个参数决定如何获取到本机的IP地址。
出于稳定性考虑，当使用A记录时默认使用curl -s https://pv.sohu.com/cityjson作为获取IP的方式，
当使用AAAA记录时默认使用curl -s6 https://ipv6-test.com/api/myip.php作为获取IP的方式，
你也可以指定自己喜欢的获取IP方式。输入格式为需要执行的命令。
请不要在命令中带双引号！解析配置文件时候会过滤掉！${Font_Suffix}"
}

function_document_AliDDNS_DNS(){
	echo -e "${Msg_Info}${Font_Green}DNS 说明
这个参数决定如何获取到DDNS域名当前的解析记录。
会使用nslookup命令查询，此参数控制使用哪个DNS服务器进行解析。
默认使用8.8.8.8进行查询${Font_Suffix}"
}

function_document_Telegram_URL(){
	echo -e "${Msg_Info}${Font_Green}Telegram Bot URL 说明
这个参数设置用于Telegram Bot推送的URL。
获取URL请移步：
https://t.me/notificationme_bot${Font_Suffix}"
}

# 获取本机IP
function_AliDDNS_GetLocalIP(){
	echo -e "${Msg_Info}正在获取本机IP……"
	if [ -z "$__Local_IP_BIN" ];then
		echo -e "${Msg_Error}本机IP参数为空或无效！"
		echo -e "${Msg_Fail}程序运行出现致命错误，正在退出……"
		exit 1
	fi
	local __CNT=0
	while :;do
		__Local_IP=`$__Local_IP_BIN` && break
		echo -e "${Msg_Error}未能获取本机IP！命令返回错误代码: [$?]"
		__CNT=$(( $__CNT + 1 ))
		[ $retry_count -gt 0 -a $__CNT -gt $retry_count ] && echo -e "${Msg_Warning}第$retry_count次重新获取IP失败，程序退出……" && exit 1
		echo -e "${Msg_Warning}获取IP失败 - 在$retry_seconds秒后进行第$__CNT次重试"
		sleep $retry_seconds
	done
	if [ "$__TYPE" = A ];then
		__Local_IP=`echo $__Local_IP | grep -m 1 -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}"`
	else
		__Local_IP=`echo $__Local_IP | grep -m 1 -o "\(\([0-9A-Fa-f]\{1,4\}:\)\{1,\}\)\(\([0-9A-Fa-f]\{1,4\}\)\{0,1\}\)\(\(:[0-9A-Fa-f]\{1,4\}\)\{1,\}\)"`
	fi
	if [ -z "$__Local_IP" ];then
		echo -e "${Msg_Error}获取本机IP失败！正在退出……"
		exit 1
	fi
	echo -e "${Msg_Info}本机IP：$__Local_IP"
}

function_AliDDNS_DomainIP(){
	echo -e "${Msg_Info}正在获取 $([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN 的IP……"
	__DomainIP=`nslookup -query=$__TYPE $([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN $__DNS`
	if [ "$?" = 1 ];then
		local __CNT=0
		while [ -z "$__DomainIP" ];do
			__CNT=$(( $__CNT + 1 ))
			[ $retry_count -gt 0 -a $__CNT -gt $retry_count ] && echo -e "${Msg_Warning}第$retry_count次重新获取域名IP失败，程序退出……" && exit 1
			echo -e "${Msg_Warning}获取IP失败 - 在$retry_seconds秒后进行第$__CNT次重试"
			sleep $retry_seconds
			__DomainIP=`nslookup -query=$__TYPE $([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN $__DNS`
		done
	fi
	echo -e "${Msg_Info}域名类型：$__TYPE"
	echo -e "${Msg_Info}nslookup检测结果:"
	# 如果执行成功，分离出结果中的IP地址
	__DomainIP=`echo "$__DomainIP" | grep -v '#' | grep 'Address:' | tail -n1 | awk '{print $NF}'`
	if [ -z "$__DomainIP" ];then
		echo -e "${Msg_Info}解析结果：$([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN -> (结果为空)"
		echo -e "${Msg_Info}$([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN 未检测到任何有效的解析记录，可能是DNS记录不存在或尚未生效"
		return
	fi
	# 进行判断，如果本次获取的新IP和旧IP相同，结束程序运行
	if [ "$__Local_IP" = "$__DomainIP" ];then
		echo -e "${Msg_Info}当前IP ($__Local_IP) 与 $([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN ($__DomainIP) 的IP相同"
		echo -e "${Msg_Success}未发生任何变动，无需进行改动，正在退出……"
		exit 0
	fi
	echo -e "${Msg_Info}当前IP ($__Local_IP) 与 $([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN ($__DomainIP) 的IP不同，需要更新(可能已更新尚未生效)"
}

# 百分号编码
percentEncode(){
	if [ -z "${1//[A-Za-z0-9_.~-]/}" ];then
		echo -n "$1"
	else
		local string=$1;local i=0;local ret chr
		while [ $i -lt ${#string} ];do
			chr=${string:$i:1}
			[ -z "${chr#[^A-Za-z0-9_.~-]}" ] && chr=$(printf '%%%02X' "'$chr")
			ret="$ret$chr"
			i=$(( $i + 1 ))
		done
		echo -n "$ret"
	fi
}

# 发送请求函数
aliyun_transfer(){
	local __CNT=0;__URLARGS=

	# 添加请求参数
	for string in $*;do
		case "${string%%=*}" in
			Format|Version|AccessKeyId|SignatureMethod|Timestamp|SignatureVersion|SignatureNonce|Signature);; # 过滤公共参数
			*) __URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}");;
		esac
	done
	__URLARGS="${__URLARGS:1}"

	# 附加公共参数
	string="Format=JSON";__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="Version=2015-01-09";__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="AccessKeyId=$__ID";__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="SignatureMethod=HMAC-SHA1";__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="Timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ');__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="SignatureVersion=1.0";__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="SignatureNonce="$(cat '/proc/sys/kernel/random/uuid');__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="Line=default";__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")

	# 对请求参数进行排序，用于生成签名
	string=$(echo -n "$__URLARGS" | sed 's/\'"&"'/\n/g' | LC_ALL=C sort | sed ':label; N; s/\n/\'"&"'/g; b label')
	# 构造用于计算签名的字符串
	string="GET&"$(percentEncode "/")"&"$(percentEncode "$string")
	# 字符串计算签名值
	local signature=$(echo -n "$string" | openssl dgst -sha1 -hmac "$__KEY&" -binary | openssl base64)
	# 附加签名参数
	string="Signature=$signature";__URLARGS="$__URLARGS&"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")

	while ! __TMP=`curl -Ss "https://alidns.aliyuncs.com/?$__URLARGS" 2>&1`;do
		echo -e "${Msg_Error}cURL 错误信息: [$__TMP]"
		__CNT=$(( $__CNT + 1 ))
		[ $retry_count -gt 0 -a $__CNT -gt $retry_count ] && echo -e "${Msg_Warning}第$retry_count次重试失败，程序退出……" && exit 1
		echo -e "${Msg_Warning}传输失败 - 在$retry_seconds秒后进行第$__CNT次重试"
		sleep $retry_seconds
	done
	__ERR=`echo $__TMP | jq -r .Code`
	[ $__ERR = null ] && return 0
	if [ "$__ERR" = LastOperationNotFinished ];then
		echo -e "${Msg_Error}最后一次操作未完成,2秒后重试"
		return 1
	fi
	echo -e "${Msg_Error}阿里云错误代码: [$__ERR]"
	[ "$__ERR" = InvalidAccessKeyId.NotFound ] && echo -e "${Msg_Error}无效 [AccessKey ID]！"
	[ "$__ERR" = SignatureDoesNotMatch ] && echo -e "${Msg_Error}无效 [AccessKey Secret]！"
	[ "$__ERR" = InvalidDomainName.NoExist ] && echo -e "${Msg_Error}域名不存在！"
	[ "$__ERR" = InvalidDomainName.Format ] && echo -e "${Msg_Error}无效域名！"
	[ "$__ERR" = QuotaExceeded.TTL ] && echo -e "${Msg_Error}[TTL]免费版只能设置600到86400之间"
	[ "$__ERR" = InvalidTTL ] && echo -e "${Msg_Error}[TTL]不能超过86400"
	exit 1
}

# 添加记录值
add_domain(){
	while ! aliyun_transfer "Action=AddDomainRecord" "DomainName=$__DOMAIN" "RR=$__HOST" "Type=$__TYPE" "Value=$__Local_IP" "TTL=$__TTL";do
		sleep 2
	done
	echo -e "${Msg_Success}添加解析记录成功: [$([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN],[IP:$__Local_IP],[TTL:$__TTL]"
}

# 启用解析记录
enable_domain(){
	while ! aliyun_transfer "Action=SetDomainRecordStatus" "RecordId=$__RECID" "Status=Enable";do
		sleep 2
	done
	echo -e "${Msg_Success}启用解析记录成功"
}

# 修改记录值
update_domain(){
	while ! aliyun_transfer "Action=UpdateDomainRecord" "RecordId=$__RECID" "RR=$__HOST" "Type=$__TYPE" "Value=$__Local_IP" "TTL=$__TTL";do
		sleep 2
	done
	echo -e "${Msg_Success}修改解析记录成功: [$([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN],[IP:$__Local_IP],[TTL:$__TTL]"
}

# 如果你有动手能力，可以尝试定制ServerChan推送的消息内容
function_ServerChan_SuccessMsgPush(){
	ServerChan_ServerFriendlyName=`sed '/^ServerChan_ServerFriendlyName=/!d;s/.*=//' $Config_configdir/config-ServerChan.cfg 2>/dev/null | sed 's/\"//g'`
	ServerChan_SCKEY=`sed '/^ServerChan_SCKEY=/!d;s/.*=//' $Config_configdir/config-ServerChan.cfg 2>/dev/null | sed 's/\"//g'`
	if [ -n "$ServerChan_ServerFriendlyName" ] && [ -n "$ServerChan_SCKEY" ];then
		echo -e "${Msg_Info}检测到ServerChan配置，正在推送消息到ServerChan平台……"
		ServerChan_Text="服务器IP发生变动_AliDDNS"
		ServerChan_Content="服务器：${ServerChan_ServerFriendlyName}，新的IP为：${__Local_IP}，请注意服务器状态"
		while ! __TMP=`curl -m 5 -Ssd "&desp=$ServerChan_Content" https://sc.ftqq.com/$ServerChan_SCKEY.send?text=$ServerChan_Text 2>&1`;do
			echo -e "${Msg_Error}ServerChan 推送失败 (cURL 错误信息: [$__TMP])"
			__CNT=$(( $__CNT + 1 ))
			[ $retry_count -gt 0 -a $__CNT -gt $retry_count ] && echo -e "${Msg_Warning}第$retry_count次重试失败，程序退出……" && exit 1
			echo -e "${Msg_Warning}传输失败 - 在$retry_seconds秒后进行第$__CNT次重试"
			sleep $retry_seconds
		done
		echo -e "$([ "$(echo $__TMP | jq -r .errno)" = 0 ] && echo ${Msg_Success} || echo ${Msg_Error})ServerChan返回信息:[`echo $__TMP | jq -r .errmsg | sed 's/^\w\|\s\w/\U&/g'`]"
	fi
}

# 如果你有动手能力，可以尝试定制Telegram推送的消息内容
function_Telegram_SuccessMsgPush(){
	Telegram_ServerFriendlyName=`sed '/^Telegram_ServerFriendlyName=/!d;s/.*=//' $Config_configdir/config-Telegram.cfg 2>/dev/null | sed 's/\"//g'`
	Telegram_URL=`sed '/^Telegram_URL=/!d;s/.*=//' $Config_configdir/config-Telegram.cfg 2>/dev/null | sed 's/\"//g'`
	if [ -n "$Telegram_ServerFriendlyName" ] && [ -n "$Telegram_URL" ];then
		echo -e "${Msg_Info}检测到Telegram配置，正在推送消息到Telegram平台……"
		Telegram_Text="服务器：${Telegram_ServerFriendlyName}，新的IP为：${__Local_IP}，请注意服务器状态"
		while :;do
			__TMP=`curl -m 5 -Ssd "text=$Telegram_Text" $Telegram_URL 2>&1` && break
			[ $? = 52 ] && echo -e "${Msg_Error}Telegram URL设置错误，程序退出……" && exit 1
			echo -e "${Msg_Error}Telegram Bot 推送失败 (cURL 错误信息: [$__TMP])"
			__CNT=$(( $__CNT + 1 ))
			[ $retry_count -gt 0 -a $__CNT -gt $retry_count ] && echo -e "${Msg_Warning}第$retry_count次重试失败，程序退出……" && exit 1
			echo -e "${Msg_Warning}传输失败 - 在$retry_seconds秒后进行第$__CNT次重试"
			sleep $retry_seconds
		done
		echo -e "$([ "$(echo $__TMP | jq -r .result.body.ok)" = true ] && echo ${Msg_Success}Telegram Bot 成功推送 || echo ${Msg_Error}Telegram Bot返回信息:[`echo $__TMP | jq -r .result.body.description`])"
	fi
}

# 获取域名解析记录
describe_domain(){
	ret=0
	while ! aliyun_transfer "Action=DescribeSubDomainRecords" "SubDomain=$__HOST.$__DOMAIN" "Type=$__TYPE";do
		sleep 2
	done
	__TMP=`echo $__TMP | jq -r .DomainRecords.Record[]`
	echo -e "${Msg_Info}AliDNS API检测结果:"
	if [ -z "$__TMP" ];then
		echo -e "${Msg_Info}解析记录不存在: [$([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN]"
		ret=1
	else
		__STATUS=`echo $__TMP | jq -r .Status`
		__RECIP=`echo $__TMP | jq -r .Value`
		if [ "$__STATUS" != ENABLE ];then
			echo -e "${Msg_Info}解析记录被禁用"
			ret=$(( $ret | 2 ))
		fi
		if [ "$__RECIP" != "$__Local_IP" ];then
			echo -e "${Msg_Info}解析记录需要更新: [解析记录IP:$__RECIP] [本地IP:$__Local_IP]"
			ret=$(( $ret | 4 ))
		fi
	fi
	if [ $ret = 0 ];then
		echo -e "${Msg_Success}解析记录不需要更新: [解析记录IP:$__RECIP] [本地IP:$__Local_IP]"
	elif [ $ret = 1 ];then
		sleep 3
		add_domain
	else
		__RECID=`echo $__TMP | jq -r .RecordId`
		[ $(( $ret & 2 )) -ne 0 ] && sleep 3 && enable_domain
		[ $(( $ret & 4 )) -ne 0 ] && sleep 3 && update_domain && (function_ServerChan_SuccessMsgPush;function_Telegram_SuccessMsgPush)
	fi
}

Entrance_AliDDNS_Configure_And_Run(){
	function_Check_Root
	function_Check_Enviroment
	function_Install_Enviroment
	function_AliDDNS_SetConfig
	function_AliDDNS_WriteConfig
	function_AliDDNS_CheckConfig
	function_AliDDNS_GetLocalIP
	function_AliDDNS_DomainIP
	describe_domain
	exit 0
}

Entrance_AliDDNS_RunOnly(){
	function_Check_Root
	function_AliDDNS_CheckConfig
	[ "$Switch_AliDDNS_Config_Exist" = 0 ] && echo -e "${Msg_Error} 未检测到任何有效配置，请先不带参数运行程序以进行配置！" && exit 1
	function_Check_Enviroment
	function_Install_Enviroment
	function_AliDDNS_GetLocalIP
	function_AliDDNS_DomainIP
	describe_domain
	exit 0
}

Entrance_AliDDNS_ConfigureOnly(){
	function_Check_Root
	function_Check_Enviroment
	function_Install_Enviroment
	function_AliDDNS_SetConfig
	function_AliDDNS_WriteConfig
	echo -e "${Msg_Success}配置文件写入完成"
	exit 0
}

Entrance_ServerChan_Config(){
	function_Check_Root
	function_Check_Enviroment
	function_ServerChan_Configure
	function_ServerChan_WriteConfig
	echo -e "${Msg_Success}配置文件写入完成，重新执行脚本即可激活ServerChan推送功能"
	exit 0
}

Entrance_Telegram_Config(){
	function_Check_Root
	function_Check_Enviroment
	function_Telegram_Configure
	function_Telegram_WriteConfig
	echo -e "${Msg_Success}配置文件写入完成，重新执行脚本即可激活Telegram推送功能"
	exit 0
}

Entrance_Global_CleanEnv(){
	echo -e "${Msg_Info}正在清理环境……"
	rm -f /etc/OneKeyAliDDNS/config.cfg
	rm -f ~/OneKeyAliDDNS/config.cfg
	rm -f /etc/OneKeyAliDDNS/config-ServerChan.cfg
	rm -f ~/OneKeyAliDDNS/config-ServerChan.cfg
	rm -f /etc/OneKeyAliDDNS/config-Telegram.cfg
	rm -f ~/OneKeyAliDDNS/config-Telegram.cfg
	echo -e "${Msg_Success}环境清理完成，重新执行脚本以开始配置"
	exit 0
}

Entrance_ServerChan_CleanEnv(){
	echo -e "${Msg_Info}正在清理ServerChan配置……"
	rm -f /etc/OneKeyAliDDNS/config-ServerChan.cfg
	rm -f ~/OneKeyAliDDNS/config-ServerChan.cfg
	echo -e "${Msg_Success}ServerChan配置清理完成，重新执行脚本以开始配置"
	exit 0
}

Entrance_Telegram_CleanEnv(){
	echo -e "${Msg_Info}正在清理Telegram配置……"
	rm -f /etc/OneKeyAliDDNS/config-Telegram.cfg
	rm -f ~/OneKeyAliDDNS/config-Telegram.cfg
	echo -e "${Msg_Success}Telegram配置清理完成，重新执行脚本以开始配置"
	exit 0
}

Entrance_Version(){
	echo -e "
# AliDDNS 工具 (阿里云云解析修改工具)
#
# Build:     ${BuildTime}
# 支持平台:  CentOS/Debian/Ubuntu
# 作者:      Small_5 (基于iLemonrain的AliDDNS改进)
"
	exit 0
}

case "$1" in
	run)Entrance_AliDDNS_RunOnly;;
	config)Entrance_AliDDNS_ConfigureOnly;;
	clean)Entrance_Global_CleanEnv;;
	clean_chan)Entrance_ServerChan_CleanEnv;;
	clean_tg)Entrance_Telegram_CleanEnv;;
	version)Entrance_Version;;
	*)echo -e "${Font_Blue} AliDDNS 工具 (阿里云云解析修改工具)${Font_Suffix}

使用方法 (Usage)：
$0 run             配置并运行工具 (如果已有配置将会直接运行)
$0 config          仅配置工具
$0 clean           清理配置文件及运行环境
$0 clean_chan      清理ServerChan配置文件
$0 clean_tg        清理Telegram配置文件
$0 version         显示版本信息

";;
esac

echo -e "${Msg_Info}选择你要使用的功能: "
echo -e " 1. 配置并运行 AliDDNS \n 2. 仅配置 AliDDNS \n 3. 仅运行 AliDDNS \n 4. 配置ServerChan微信推送 \n 5. 配置Telegram推送 \n 6. 清理环境 \n 7. 清理ServerChan配置文件 \n 8. 清理Telegram配置文件 \n 0. 退出 \n"
read -p "输入数字以选择:" Function

if [ "${Function}" = 1 ];then
	Entrance_AliDDNS_Configure_And_Run
elif [ "${Function}" = 2 ];then
	Entrance_AliDDNS_ConfigureOnly
elif [ "${Function}" = 3 ];then
	Entrance_AliDDNS_RunOnly
elif [ "${Function}" = 4 ];then
	Entrance_ServerChan_Config
elif [ "${Function}" = 5 ];then
	Entrance_Telegram_Config
elif [ "${Function}" = 6 ];then
	Entrance_Global_CleanEnv
elif [ "${Function}" = 7 ];then
	Entrance_ServerChan_CleanEnv
elif [ "${Function}" = 8 ];then
	Entrance_Telegram_CleanEnv
else
	exit 0
fi
