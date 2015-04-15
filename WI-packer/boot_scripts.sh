SERVICE="rc-local.service"
FILE="/usr/lib/systemd/system/$SERVICE"
INIT_SCRIPT="/etc/rc.local"
BOOT_SCRIPT_WI=$(cat boot_scripts_wi.sh)

cat <<COMMANDS > $FILE
[Unit]
Description=$INIT_SCRIPT Compatibility

[Service]
Type=oneshot
ExecStart=$INIT_SCRIPT
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
COMMANDS

cat <<INIT_SCRIPT_CONTENT > $INIT_SCRIPT
#!/usr/bin/env bash

echo boot time: \`date\` >> /home/vagrant/debug

"$BOOT_SCRIPT_WI"

exit 0
INIT_SCRIPT_CONTENT

chmod +x $INIT_SCRIPT
systemctl enable $SERVICE
