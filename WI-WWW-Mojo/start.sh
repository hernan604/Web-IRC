clear
#   export DB_NAME="dbi:Pg:dbname=cmt"
#   export DB_USER="hernan"
#   export DB_PASS="hernan"
export MOJO_LISTEN="http://*:8081"
export DBIC_TRACE=1
#perl -I../WI-WWW-Mojo/lib/ -I./lib myapp.pl
source ../env_vars.sh
perl -I../WI-Main/lib/ -I../WI-DB/lib/ -I./lib myapp.pl
