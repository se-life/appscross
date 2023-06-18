
#!/bin/bash

echo -e “\e[32m =============================================== \e[0m”
echo -e “\e[32m The script just support NetworkManager by LaoE. \e[0m”
echo -e “\e[32m Mod by U to support dhclient&dhcpcd. \e[0m”
echo -e “\e[32m =============================================== \e[0m”

echo “Step 1-Auto detecting DHCP client... ”

dhcp_client=""
if [[ -x $(command -v nmcli) ]]; then
  dhcp_client="NetworkManager"
elif [[ -x $(command -v dhcpcd) ]]; then
  dhcp_client="dhcpcd"
elif [[ -x $(command -v dhclient) ]]; then
  dhcp_client="dhclient"
else
  echo -e “\e[31m No supported DHCP client found. \e[0m”
  exit 1
fi

case $dhcp_client in
  "NetworkManager")
    echo "Detected NetworkManager DHCP client."
	echo “Step 2-Writing script cf-ddns6.sh to default location... ... ”
	
    cat << EOF > /bin/cf-ddns6.sh
	#!/bin/sh

	IP6="$1"

	if [ -z "$IP6" ]; then
		IP6=$(ip -6 addr show dev {interface} | awk '/inet6 .* global/ { print $2 }' | awk -F "/" '{ print $1 }')
	fi

	if [ -z "$IP6" ]; then
		echo "error:unable to obtain IPv6 address."
		exit 1
	fi

	response=\$(curl -s -o /dev/null -w %{http_code} --request PUT \
		--url "https://api.cloudflare.com/client/v4/zones/{ZoneID}/dns_records/{RecordID}" \
		--header "Content-Type: application/json" \
		--header "X-Auth-Email: {Email}" \
		--header "Authorization: Bearer {Token}" \
		--data '{
		"type": "AAAA",
		"name": "{Fullname}",
		"content": "'"\$IP6"'",
		"proxied": false
		}')
	if [ "\$response" = "200" ]; then
		echo "info:DNS record is updated successfully."
	else
		echo "warning:DNS record update failed and returned HTTP status code: \$response."
	fi
	EOF
	
	echo -e “\e[32m Finished to create /bin/cf-ddns6.sh. \e[0m”
	echo -e “\e[31m Be sure to modify the replacement \{ZoneID\},\{RecordID\},\{Email\},\{Token\},\{Fullname\}. \e[0m”
	
	chmod +x /bin/cf-ddns6.sh
	
	echo “Step 3-Writing script 99-ip6-address-change to default location... ... ”
  
	cat << EOF > /etc/NetworkManager/dispatcher.d/99-ip6-address-change
    #!/bin/sh

	interface=$1
	action=$2

	ipv6_file="/etc/NetworkManager/dispatcher.d/previous_ipv6.txt"
	if [ "$action" = "dhcp6-change" ] || [ "$action" = "connectivity-change" ] || [ "$action" = "up" ]; then
		current_ipv6=$(ip -6 addr show dev eth0 | awk '/inet6 .* global/ { print $2 }')

		if [ -f "$ipv6_file" ]; then
			previous_ipv6=$(cat "$ipv6_file")
			if [ "$current_ipv6" != "$previous_ipv6" ]; then
				/bin/cf-ddns6.sh "$current_ipv6"
				echo "$current_ipv6" > "$ipv6_file"
			fi
		else
			echo "$current_ipv6" > "$ipv6_file"
		fi
	fi
	EOF
	
	echo -e “\e[32m Finished to create /etc/NetworkManager/dispatcher.d/99-ip6-address-change. \e[0m”
	echo -e “\e[31m Be sure to network interface is \"eth0\" and modify if not. \e[0m”
	
	chmod +x /etc/NetworkManager/dispatcher.d/99-ip6-address-change
	chown root:root /etc/NetworkManager/dispatcher.d/99-ip6-address-change
	
    ;;
  
  "dhcpcd")
    echo "Detected dhcpcd DHCP client."
    #echo "Executing dhcpcd commands..."
    
    ;;
  
  "dhclient")
    echo "Detected dhclient DHCP client."
    #echo "Executing dhclient commands..."
    
    ;;
esac
