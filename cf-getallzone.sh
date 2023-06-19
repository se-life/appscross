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
echo "以下是域名及域ID列表："
echo ""


echo "$CF_DOMAINS" > cf-$(date +%Y%m%d-%H%M%S).json
echo "$CF_DOMAINS" | jq '.result[] | [.name, .id] | @tsv'
echo ""
