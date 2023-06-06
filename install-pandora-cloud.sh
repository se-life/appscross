#!/bin/bash

SERVICE_NAME="pandora-cloud"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

# 检查Python版本是否符合要求
python_version=$(python3 -c 'import platform; print(platform.python_version())')
required_version="3.7"

if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo "需要安装Python $required_version 或更高版本"
    exit 1
fi

# 检查pip3是否已安装
if ! command -v pip3 &> /dev/null; then
    echo "未找到pip3，正在安装..."
    sudo apt install python3-venv python3-pip
fi

# 安装pandora服务
echo "正在安装pandora服务..."
pip install pandora-chatgpt
pip install pandora-chatgpt[cloud]


# 创建服务文件
sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=Pandora ChatGPT Service

[Service]
Type=simple
ExecStart=/usr/local/bin/pandora-cloud --server 0.0.0.0:80

[Install]
WantedBy=multi-user.target
EOF

# 重新加载Systemd配置并启动服务

sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo "pandora-cloud服务已经启动..."
