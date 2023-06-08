﻿#!/bin/sh

cat << EOF > /bin/cf-ddns6.sh
#!/bin/sh
sleep 10
IP6=\$(ip -6 addr show dev {interface} | awk '/global/ {print \$2}' | awk -F "/" '{print \$1}')
if [ -z "\$IP6" ]; then
  exit
fi
curl --request PUT \
  --url "https://api.cloudflare.com/client/v4/zones/zone_identifier/dns_records/{RecordID}" \
  --header "Content-Type: application/json" \
  --header "X-Auth-Email: {Email}" \
  --header "Authorization: Bearer {Token}" \
  --data '{
  "type": "AAAA",
  "name": "{Domainname}",
  "content": "'"\$IP6"'",
  "proxied": false
}'
EOF
chmod +x /bin/cf-ddns6.sh