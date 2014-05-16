#!/bin/bash

# fail on any error
set -e

# If the user has not defined a specific password they'd prefer to use for the
# MySQL root account, generate a 32 digit random new password using the following
# options:
#   -s: Generate completely random passwords
#   -n: Include at least one number in the password
#   -B: Don't include ambiguous characters in the password
#   -c: Include at least one capital letter in the password

if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    export MYSQL_ROOT_PASSWORD="$(pwgen -snBc 32 1)"
    # log the newly generated MySQL root password to the Docker logs so the user
    # can look it up for initial provisioning of the server
    echo "Generated MySQL Root Password: \"$MYSQL_ROOT_PASSWORD\""
    echo "For security reasons, please log into MySQL and change this password \
        immediately."
else
    echo "Using user-defined password for the MySQL root account."
fi

# start mysql in background to be able to run the following SQL
sudo -u mysql mysqld >/dev/null 2>&1 & 

while [[ ! -S /var/run/mysqld/mysqld.sock ]]; do
    # wait for mysql to start
    inotifywait -qq -e create /var/run/mysqld/mysqld.sock
done

# set the mysql root password
mysqladmin -u root password "$MYSQL_ROOT_PASSWORD"

# stop mysql
killall -w -s SIGTERM mysqld

# all was successful, remove pwgen and inotify-tools
apt-get remove --yes -q 2 pwgen inotify-tools

# all done
exit 0
