#BOOT SCRIPT WI::IRC

COMMANDS="
cd ~/perl/Web-IRC/WI-Main && sh start &
cd ~/perl/Web-IRC/WI-WWW-Mojo && sh start &
cd ~/perl/Web-IRC/WI-IRC && sh start_server.sh &
"

sudo su - vagrant -c "$COMMANDS"
