#!/bin/sh

cat << EOF > /bin/cf-ddns6.sh
#!/bin/sh
sleep 10
IP6=\$(ip -6 addr show dev {Interface} | awk '/global/ {print \$2}' | awk -F "/" '{print \$1}')
if [ -z "\$IP6" ]; then
  exit
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
  echo "DNS记录更新成功"
else
  echo "DNS记录更新失败，HTTP状态码: \$response"
fi
EOF
chmod +x /bin/cf-ddns6.sh
