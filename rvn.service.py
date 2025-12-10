[Unit]
Description=Realer Virtual Network (RVN) — private ghost proxy
After=network.target

[Service]
Type=simple
ExecStart=/opt/RVN/rvn
Restart=always
RestartSec=5
User=root
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
