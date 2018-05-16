#!/usr/bin/env bash
set -e

CONTAINER_IP=$(grep $(hostname) /etc/hosts | awk '{print $1}')
CURR_FDB_UID=$(id -u foundationdb)
CURR_FDB_GID=$(id -g foundationdb)

# Replace the default IP address with the container's IP.
sed -i s/@.*:/@$CONTAINER_IP:/ /etc/foundationdb.default/fdb.cluster

# Copy the default files into volumes if they do not exist.
for DIR in $FDB_USER_DIRS
do
        cp -r --no-clobber $DIR.default/* $DIR
done

# Sync the foundationdb user and group with the host.
if [ $CURR_FDB_UID != $FDB_UID -o $CURR_FDB_GID != $FDB_GID ]
then
        groupmod -g $FDB_GID --non-unique foundationdb
        usermod -g $FDB_GID -u $FDB_UID --non-unique foundationdb
        chown -R foundationdb:foundationdb $FDB_USER_DIRS
fi

$@ &

trap 'kill $!' SIGHUP SIGINT SIGQUIT SIGTERM
wait
