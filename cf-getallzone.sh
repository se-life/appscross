#!/bin/bash

read -p "请输入Cloudflare账户电子邮件地址: " CF_EMAIL
read -s -p "请输入Cloudflare API密钥: " CF_API_KEY

echo ""
echo "正在获取域名ID和域名..."
CF_DOMAINS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones" \
     -H "X-Auth-Key: $CF_API_KEY" \
     -H "X-Auth-Email: $CF_EMAIL" \    
     -H "Content-Type:application/json")

echo ""
echo "以下是域名及域名ID列表："
echo ""

echo "$CF_DOMAINS" > cf-$(date +%Y%m%d-%H%M%S).json

domainlist=($(echo "$CF_DOMAINS" | jq -r '.result[] | [.name, .id] | @csv' | sed -e 's/,/ /g' -e 's/\"//g'))

printf "\e[34m%-5s %-20s %-48s\e[0m\n" "索引" "域名" "域名ID"
printf "%s\n" "========================================================="

for ((i = 0; i < ${#domainlist[@]}/2; i++)); do
  index=$((i+1))
  if (( index < 10 )); then
    printf "%-5s %-20s %-48s\n" "0$index" "${domainlist[i*2]}" "${domainlist[i*2+1]}"
  else
    printf "%-5s %-20s %-48s\n" "$index" "${domainlist[i*2]}" "${domainlist[i*2+1]}"
  fi
done
