clear
#   export DB_NAME="dbi:Pg:dbname=cmt"
#   export DB_USER="hernan"
#   export DB_PASS="hernan"
export MOJO_LISTEN="http://*:9999"
export DBIC_TRACE=1
#perl -I../WI-WWW-Mojo/lib/ -I./lib myapp.pl
source ../env_vars.sh
perl -I../WI-DB/lib/ -I./lib myapp.pl
