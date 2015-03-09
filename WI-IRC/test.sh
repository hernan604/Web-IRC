source ../env_vars.sh
perl test.pl ; ps ax | grep server | awk '{print $1}' | xargs kill -9
