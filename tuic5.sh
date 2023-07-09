#!/bin/bash

alias ee='echo -e'
shopt -s expand_aliases
source ~/.bash_profile
export LANG=en_US.UTF-8

red()
{
	echo -e "\033[31m$1\033[0m"
}
green()
{
	echo -e "\033[32m$1\033[0m"
}
blue()
{
	echo -e "\033[36m$1\033[0m"
}

RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[36m"
PLAIN="\033[0m"

uninstall()
{
	select=$([ $# -gt 0 ] && echo "清除" || echo "卸载")
	echo "正在${select}Tuic..."
	if [[ -z $(systemctl list-unit-files --type=service | grep tuic) ]]; then
		ee "没有在主机${BLUE}$(hostname)${PLAIN}上检测到安装有Tuic，无需${select}..." 
		read -n 1 -s -r -p "请按任意键返回..." 
		return 0 
	fi
	systemctl stop tuic.service >/dev/null 2>&1
	systemctl disable tuic.service >/dev/null 2>&1
	if [ -f /etc/systemd/system/tuic.service ]; then
		rm -f /etc/systemd/system/tuic.service >/dev/null 2>&1
	fi
	if [ -d /usr/local/bin/tuic ]; then
		rm -rf /usr/local/bin/tuic >/dev/null 2>&1
	fi
	
	if [ $# -gt 0 ]; then
		ee "Tuic已卸载，脚本将完全清除socat、qrencode、acme.sh..." && sleep 0.3	
		dpkg --configure -a
		apt purge socat qrencode -y >/dev/null 2>&1
		apt autoremove socat qrencode -y >/dev/null 2>&1
		~/.acme.sh/acme.sh --uninstall  >/dev/null 2>&1
  		rm -rf ~/.acme.sh
		sed -i 'acme.sh' /var/spool/cron/crontabs/root >/dev/null 2>&1
	fi
	green "${select}Tuic完毕！"
	read -n 1 -s -r -p "请按任意键返回..."
	return 0
}

switch()
{
	if [ ! -f "/usr/local/bin/tuic/tuic-server" ]; then
		ee "Tuic${RED}尚未安装${PLAIN}，请安装后再运行..."
		read -n 1 -s -r -p "请按任意键返回..."
		return 1
	fi
	if [ ! -f "/etc/systemd/system/tuic.service" ]; then
		echo -e "${RED}未检测${PLAIN}到Tuic的${RED}系统服务文件${PLAIN}，请修复后运行..."
		read -n 1 -s -r -p "请按任意键返回..."
		return 1
	fi
	
	service_name="tuic.service"
	status=$(systemctl is-active ${service_name})
	[[  status != "active" ]] && select="启动" || select="停止"
	if [ $status = "active" ]; then
		ee -n "正在${RED}停止${PLAIN}Tuic..."
		systemctl stop "${service_name}"
	else
		ee -n "正在${GREEN}启动${PLAIN}Tuic..."
		systemctl start "${service_name}"
	fi
	echo "Tuic服务当前状态（如有异常请调试）："
	echo "------------------------------"
	systemctl status tuic.service
	echo "------------------------------"
	
	green "启停完成！" && sleep 0.3
	read -n 1 -s -r -p "请按任意键返回..."
	return 0
}

view()
{
	
	if [ ! -e "/usr/local/bin/tuic/tuic-server" -o ! -e "/usr/local/bin/tuic/config.json" ]; then
		ee "Tuic${RED}尚未安装${PLAIN}，请安装后显示客户端配置文件..."
		read -n 1 -s -r -p "请按任意键返回..."
		return 1
	fi

	cd /usr/local/bin/tuic
	ccfiles=$(ls -p *.json *.yaml -I config.json | grep -v '/\|config.json')
	[ ${#ccfiles[@]} < 4 ] && echo "提示：客户端配置文件有缺失，请注意修复..."
	for cfile in ${ccfiles[@]};	do
		clear
		green "/usr/local/bin/tuic/${cfile}"
		echo "---------------------------------------------------"
		cat "$cfile"
		echo ""
		if echo ${cfile} | grep shadowrocket ; then
			url="tuic://$(jq .host -r ${cfile}):$(jq .port -r ${cfile})?&password=$(jq .password -r ${cfile})&udp=$(jq .udp -r ${cfile})&alpn=$(jq .alpn -r ${cfile})&mode=$(jq .proto -r ${cfile})#laoe"
			echo ""
			echo "Shadowrocket分享链接为：${url}，移动端可扫描以下二维码导入："
			echo ""
			qrencode -t UTF8 -o - $url
			echo ""
		fi
		echo "---------------------------------------------------"
		ee -n "${GREEN}${cfile}${PLAIN}显示完成！"
		read -n 1 -s -r -p "按任意键继续..."
	done
	echo ""
	read -n 1 -s -r -p "显示完毕。请按任意键返回..."
	return 0
}

preinstall()
{
	#cron curl wget jq为非清理项
	ee -n "[${GREEN}pre-1${PLAIN}]安装cron,curl,wget,jq... ..."
	if ! dpkg -s cron >/dev/null 2>&1; then
		apt install cron -y >/dev/null 2>&1
	fi
	if ! dpkg -s curl >/dev/null 2>&1; then
		apt install curl -y >/dev/null 2>&1
	fi
	if ! dpkg -s wget >/dev/null 2>&1; then
		apt install wget -y >/dev/null 2>&1
	fi
	if ! dpkg -s jq >/dev/null 2>&1; then
		apt install jq -y >/dev/null 2>&1
	fi
	green "安装完成！" && sleep 0.3
		
	#socat acme.sh qrencode为清理项
	ee -n "[${GREEN}pre-2${PLAIN}]安装socat,acme.sh,qrencode... ..."
	apt install socat qrencode -y >/dev/null 2>&1
	curl -s https://get.acme.sh | sh -s email=$(date +%s%N | md5sum | cut -c 1-12)@gmail.com >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		ee "${RED}acme.sh安装失败${PLAIN}，可能的问题包括但不限于："
		echo "-------------------------------------------------------"
		echo " 1-系统网络无法访问Github等站点；"
		echo " 2-系统启用了防火墙且阻止了对acme.sh下载点的访问；"
		echo " 3-系统所在域名启用了启用了阻止对acme.sh下载点的访问的策略。"
		echo "-------------------------------------------------------"
		rm -rf ~/.acme.sh
		read -n 1 -s -r -p "请按任意键退出，进行相应处理后继续安装..." && exit 1
	fi
	green "安装完成！" && sleep 0.3
	
	return 0
}

install()
{
	service_name="tuic.service"
	if systemctl is-enabled "${service_name}" >/dev/null 2>&1; then
		ee "${service_name}已安装，不必重复安装！"
		read -n 1 -s -r -p "请按任意键返回..."
		return 0
	fi
	
	preinstall
	
	ee "【${GREEN}1${PLAIN}】正在安装、配置Tuic..."
	mkdir -p /usr/local/bin/tuic >/dev/null 2>&1
	wget --no-check-certificate https://github.com/EAimTY/tuic/releases/download/tuic-server-1.0.0/tuic-server-1.0.0-x86_64-unknown-linux-gnu -O /usr/local/bin/tuic/tuic-server >/dev/null 2>&1
	chmod +x /usr/local/bin/tuic/tuic-server
	
	ee -n "[${GREEN}1-1${PLAIN}]请指定计划使用的完整域名："
	read domain
	[[ -z $domain ]] && red "未输入域名，无法执行操作！" && exit 1
    blue "已指定计划使用的的完整域名为：${domain}" && sleep 0.2
	
	ee -n "[${GREEN}1-2${PLAIN}]请指定tuic服务使用的端口（1000-65535,默认10443）："
	read -n 5 port
	[[ -z $port ]] && port=10443
	if [[ -n $(netstat -tulnp | grep ${port}) ]]; then
		red "端口${port}被占用，请注意安装后务必释放端口..." && sleep 0.2
	else
		blue "端口${port}可用，请注意防火墙应放行端口..." && sleep 0.2
	fi
	
	ee -n "[${GREEN}1-3${PLAIN}]请指定一个UUID（默认自动生成）："
	read uuid
	[[ -z $uuid ]] && uuid=$(cat /proc/sys/kernel/random/uuid)
	blue "UUID为：${uuid}" && sleep 0.2
	
	ee -n "[${GREEN}1-4${PLAIN}]请指定一个账户密码（默认自动生成）：" 
	read pwd
	[[ -z $pwd ]] && pwd=$(date +%s%N | md5sum | cut -c 1-12)
	blue "账户密码为：${pwd}" && sleep 0.2
	
	ee -n "[${GREEN}1-5${PLAIN}]获取本机IP地址..." 
	ip=$(curl -s4m8 ip.p3terx.com -k | sed -n 1p) || ip=$(curl -s6m8 ip.p3terx.com -k | sed -n 1p)
	ee "${GREEN}获取完成！${PLAIN}"
	blue "本机IP地址为：${ip}"
	
	ee -n "【${GREEN}2${PLAIN}】正在创建服务端配置文件..." 
	cat << EOF > /usr/local/bin/tuic/config.json
{
		"server": "0.0.0.0:$port", 
		"users": {
			"$uuid": "$pwd"	
		},
		"certificate": "/usr/local/bin/tuic/fullchain.pem",
		"private_key": "/usr/local/bin/tuic/private.key",
		"auth_timeout": "3s",
		"congestion_control": "bbr",
		"alpn": ["h3", "spdy/3.1"],
		"log_level": "warn"
} 
EOF
	green "创建完成！" && sleep 0.3
	
	ee "【${GREEN}3${PLAIN}】正在配置证书..."
	echo ""
	ee -n "请选择是否由脚本通过acme.sh自动生成、获取、安装证书（${GREEN}Y${PLAIN}/${RED}N${PLAIN}，默认${GREEN}Y${PLAIN}）：" 
	read cert
	[[ -z $cert ]] && cert="Y"
	echo ""
	if [ $cert = "y" -o $cert = "Y" ]; then
		ee -n "[${GREEN}3-1${PLAIN}]正在申请、获取证书..."
		setcap 'cap_net_bind_service=+ep' /usr/bin/socat >/dev/null 2>&1
		~/.acme.sh/acme.sh --server letsencrypt --issue -d ${domain} --standalone -k ec-256 --insecure >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			ee "${RED}证书申请失败。${PLAIN}可能的原因包括但不限于："
			echo "--------------------------------------------"
			echo "1-系统开启了VPN导致IP不可达--暂时关闭VPN连接;"
			echo "2-80端口被其他应用占用--请查看后关闭相关应用;"
			echo "3-域安全策略或防火墙且没有放行80端口--放行80端口;"
			echo "4-域名解析配置不正确--登录DNS控制台/面板修改;"
			echo "5-多次重复向同一个CA申请同一个域的证书--缓缓！"
			echo "-------------------------------------------"
			
			ee "正在回退安装..."
			~/.acme.sh/acme.sh --uninstall  >/dev/null 2>&1
			rm -rf ~/.acme.sh
			rm -rf /usr/local/bin/tuic >/dev/null 2>&1
			apt purge socat qrencode -y >/dev/null 2>&1
			apt autoremove socat qrencode -y >/dev/null 2>&1
			read -n 1 -s -r -p "回退完成。按任意键退出..." 
			echo ""
			exit 1
		fi
		green "证书申请、获取完成！" && sleep 0.2
	
		ee -n "[${GREEN}3-2${PLAIN}]正在安装证书..."
		~/.acme.sh/acme.sh --installcert -d ${domain} --key-file /usr/local/bin/tuic/private.key --fullchain-file /usr/local/bin/tuic/fullchain.pem
		green "证书安装完成！" && sleep 0.3
	
	elif [ $cert = "n" -o $cert = "N" ]; then
		ee -n "[${GREEN}3-1${PLAIN}]请指定已有${RED}【私钥文件】${PLAIN}绝对路径名（默认为${BLUE}~/private.key${PLAIN}）："
		read c_key
		[[ -z $c_key ]] && c_key="/root/private.key"
		if [ -e "$c_key" ]; then
			cp $c_key /usr/local/bin/tuic/
			green "私钥文件导入完成！" && sleep 0.2
		else
			ee "私钥文件${c_key}不存在，脚本将忽略此问题并继续运行..."
		fi
		
		ee -n "[${GREEN}3-2${PLAIN}]请指定已有${RED}【证书链文件】${PLAIN}绝对路径名（默认为${BLUE}~/fullchain.pem${PLAIN}）："
		read c_fullchain
		[[ -z $c_fullchain ]] && c_fullchain="/root/fullchain.pem"
		if [ -e "$c_fullchain" ]; then
			cp $c_fullchain /usr/local/bin/tuic/
			green "证书链文件导入完成！" && sleep 0.2
		else
			ee "证书链文件${c_fullchain}不存在，脚本将忽略此问题并继续运行..."
		fi
	else
		ee "输入选项${RED}${cert}${PLAIN}错误，脚本将忽略此问题并继续运行，证书安装配置工作需要手动完成..."
		read -n 1 -s -r -p "请按任意键继续..." 
	fi
	echo ""
	
	ee -n "【${GREEN}4${PLAIN}】正在创建Tuic系统服务..."
	cat << EOF > /etc/systemd/system/tuic.service
[Unit]
Description=Tuic 1.0.0
Documentation=https://github.com/EAimTY/tuic
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/tuic/tuic-server -c /usr/local/bin/tuic/config.json
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
	
	systemctl daemon-reload >/dev/null 2>&1
	systemctl enable tuic.service >/dev/null 2>&1
	green "创建完成！" && sleep 0.3
	
	ee -n "【${GREEN}5${PLAIN}】正在创建Tuic客户端配置文件..."
	
	cat << EOF > /usr/local/bin/tuic/client-shadowrocket.json
{
  "host" : "$domain",
  "alpn" : "h3",
  "type" : "TUIC",
  "user" : "$uuid",
  "udp" : 2,
  "port" : "$port",
  "proto" : "bbr",
  "password" : "$pwd"
}
EOF

	cat << EOF > /usr/local/bin/tuic/client-tuic.json
{
    "relay": {
        "server": "$domain:$port",
        "uuid": "$uuid",
        "password": "$pwd",
        "ip": "$ip",
        "udp_relay_mode": "quic",
        "congestion_control": "bbr",
        "alpn": ["h3"]
    },
    "local": {
        "server": "127.0.0.1:10808"
    },
    "log_level": "warn"
}
EOF
	
	cat << EOF > /usr/local/bin/tuic/client-v2rayn.json
{
    "relay": {
        "server": "${domain}:${port}",
        "uuid": "$uuid",
        "password": "$pwd",
        "ip": "$ip",
        "congestion_control": "bbr",
        "alpn": ["h3","spdy/3.1"]
    },
    "local": {
        "server": "127.0.0.1:10808"
    },
    "log_level": "warn"
}
EOF

	cat << EOF > /usr/local/bin/tuic/client-clash.yaml
proxies:
  - name: Tuic
    server: $domain
    port: $port
    type: tuic
    uuid: $uuid
    password: $pwd
    ip: $ip
    alpn: [h3]
    request-timeout: 8000
    udp-relay-mode: quic
    congestion-controller: bbr

proxy-groups:
  - name: Proxy
    type: select
    proxies:
      - Tuic
      
rules:
  - GEOIP,CN,DIRECT
  - MATCH,Proxy
EOF

	green "创建完成！" && sleep 0.3
	ee "【${GREEN}6${PLAIN}】Tuic安装部署完成！"
	ee "[${GREEN}6-1${PLAIN}]tuic内核和配置文件均安装于${GREEN}/usr/local/bin/tuic/${PLAIN}目录"
	sleep 1
	ee "[${GREEN}6-2${PLAIN}]Tuic安装部署完成，服务端配置文件如下：" 
	cat /usr/local/bin/tuic/config.json
	read -n 1 -s -r -p "按任意键退出安装程序，脚本将自动启动Tuic服务..."
	echo ""
	return 0
}

if [ "$(id -u)" -ne 0 ]; then
    echo "$(whoami)不是root用户，脚本需要root权限以安装配置tuic服务，请退出后切换为root用户后运行！"
    exit 1
fi

while true; do
	clear
	echo ""
	echo "【LaoE提示】"
	ee "● 脚本仅在${GREEN}X86_64(AMD64)${PLAIN}架构${GREEN}Debian 11+(kernel 5.10+)${PLAIN}、${GREEN}Ubuntu 20.04+(kernel 5.15+)${PLAIN}实测应用"
	ee "● 脚本没有发行版本与内核检查、没有平台架构检查、没有网络连接与协议栈检查、没有GNU库检查、没有ACL检查，要么退出安装，要么一路回车，结束..."
	
	echo ""
	ee "主机${BLUE}$(hostname)${PLAIN}基本信息："
	echo "+------------------------------------------+"
	ee  "  系统版本：${BLUE}$(lsb_release -ds)${PLAIN}"
	ee  "  内核版本：${BLUE}$(uname -r)${PLAIN}"      
	ee  "  系统内存：${BLUE}$(free -m | sed -n "2,2p" | awk '{print $2}')MB${PLAIN}"
	ee  "  存储空间：${BLUE}$(df -lm | awk '{print $2}' | awk '{sum+=$1}END{print sum}')MB${PLAIN}"
	echo "+------------------------------------------+"
	echo ""
	echo "============================================"
	ee "【${BLUE}1${PLAIN}】${GREEN}安装${PLAIN}Tuic(${BLUE}I${PLAIN}nstall)"
	ee "【${BLUE}2${PLAIN}】${RED}卸载${PLAIN}Tuic(${BLUE}U${PLAIN}ninstall)"
	ee "【${BLUE}3${PLAIN}】${RED}清除${PLAIN}Tuic及依赖项(${BLUE}C${PLAIN}lear)"
	echo "--------------------------------------------"
	ee "【${BLUE}4${PLAIN}】启停Tuic(${BLUE}S${PLAIN}witch)"
	ee "【${BLUE}5${PLAIN}】显示客户端配置(${BLUE}V${PLAIN}iew)"
	echo "--------------------------------------------"
	ee "【${BLUE}0${PLAIN}】退出(${BLUE}Q${PLAIN}uit)"
	echo "============================================"
	ee -n "请输入选项【0-5】（默认为${GREEN}1${PLAIN}）：" && read choice
	[[ -z $choice ]] && choice='1'
	case $choice in
		[1iI] ) install && switch ;;
		[2uU] ) uninstall ;;
		[3cC] ) uninstall 1 ;;
		[4sS] ) switch ;;
		[5vV] ) view ;;
		[0qQ] ) break ;;
		* ) read -n 1 -s -r -p  "无效，请重新选择..." ;;
	esac
done
unalias ee

