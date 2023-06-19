#!/bin/bash


read -p "请输入Cloudflare账户电子邮件地址: " CF_EMAIL
read -s -p "请输入Cloudflare账户密码: " CF_PASSWORD
read -s -p "请输入Cloudflare API密钥: " CF_API_KEY

echo ""
echo "正在获取账户ID..."
CF_ACCOUNT_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts" \
     -H "Authorization: Bearer $CF_API_KEY" \
     -H "Content-Type:application/json" \
     --data '{"status":"active"}' | jq '.result[0].id' | tr -d '"')

echo "账户ID为：$CF_ACCOUNT_ID"

echo ""
echo "正在获取域名ID和域名..."
CF_DOMAINS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?account.id=$CF_ACCOUNT_ID" \
     -H "Authorization: Bearer $CF_API_KEY" \
     -H "Content-Type:application/json")

echo ""
echo "以下是域名列表："
echo ""

echo "$CF_DOMAINS" | jq '.result[] | [.name, .id] | @tsv'
