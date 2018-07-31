#!/usr/bin/env bash
set -e

if [ -z $FDB_MAKE_PUBLIC ]
then
	if [ ! -f /etc/foundationdb/foundationdb.conf ]
	then
        	# Replace the default IP address to be accessible from 127.0.0.1 on the host.
        	sed -i "s/^listen_address.*/listen_address = 0.0.0.0:4500/" /etc/foundationdb.default/foundationdb.conf
	fi
else
	if [ ! -f /etc/foundationdb/fdb.cluster ]
	then
		# Replace the default IP address with the container's IP.
        	CONTAINER_IP=$(grep $(hostname) /etc/hosts | awk '{print $1}')
		sed -i s/@.*:/@$CONTAINER_IP:/ /etc/foundationdb.default/fdb.cluster
	fi
fi

# Copy the default files into volumes if they do not exist.
for DIR in $FDB_USER_DIRS
do
	find $DIR.default -mindepth 1 -maxdepth 1 -exec cp -r --no-clobber {} $DIR \;
done

# Sync the foundationdb user and group with the host.
CURR_FDB_UID=$(id -u foundationdb)
CURR_FDB_GID=$(id -g foundationdb)
if [ $CURR_FDB_UID != $FDB_UID -o $CURR_FDB_GID != $FDB_GID ]
then
	groupmod -g $FDB_GID --non-unique foundationdb
	usermod -g $FDB_GID -u $FDB_UID --non-unique foundationdb
	for DIR in $FDB_USER_DIRS
	do
		mkdir -p $DIR && \
		chown -R foundationdb:foundationdb $DIR
	done
fi

$@ &

trap 'kill $!' SIGHUP SIGINT SIGQUIT SIGTERM
wait
