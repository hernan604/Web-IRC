SERVICE="rc-local-shutdown.service"
FILE="/usr/lib/systemd/system/$SERVICE"
SHUTDOWN_SCRIPT="/etc/rc.local.shutdown"

cat <<COMMANDS > $FILE
[Unit]
Description=$SHUTDOWN_SCRIPT Compatibility
ConditionFileIsExecutable=$SHUTDOWN_SCRIPT
DefaultDependencies=no
After=rc-local.service basic.target
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=$SHUTDOWN_SCRIPT
StandardInput=tty
RemainAfterExit=yes

[Install]
WantedBy=shutdown.target
COMMANDS

cat <<SHUTDOWN_SCRIPT_CONTENT > $SHUTDOWN_SCRIPT
#!/usr/bin/env bash

echo shutdown time: \`date\` >> /home/vagrant/debug

exit 0
SHUTDOWN_SCRIPT_CONTENT

chmod +x $SHUTDOWN_SCRIPT
systemctl enable $SERVICE
