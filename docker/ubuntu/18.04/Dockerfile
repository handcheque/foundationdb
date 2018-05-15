FROM ubuntu:18.04

ARG FDB_VERSION="5.1.7"
ARG FDB_DEB_REVISION="1"

ARG FDB_PKG_URL="https://www.foundationdb.org/downloads/${FDB_VERSION}/ubuntu/installers"
ARG FDB_CLIENTS_PKG="foundationdb-clients_${FDB_VERSION}-${FDB_DEB_REVISION}_amd64.deb"
ARG FDB_SERVER_PKG="foundationdb-server_${FDB_VERSION}-${FDB_DEB_REVISION}_amd64.deb"
ARG FDB_USER_DIRS="/etc/foundationdb /var/log/foundationdb /var/lib/foundationdb"

ENV FDB_USER_DIRS="${FDB_USER_DIRS}"
ENV FDB_UID="1000"
ENV FDB_GID="1000"

ADD ${FDB_PKG_URL}/${FDB_CLIENTS_PKG} /tmp/${FDB_CLIENTS_PKG}
ADD ${FDB_PKG_URL}/${FDB_SERVER_PKG} /tmp/${FDB_SERVER_PKG}

RUN apt update && \
    apt install -y python
RUN dpkg -i /tmp/${FDB_CLIENTS_PKG} /tmp/${FDB_SERVER_PKG} && \
    rm /tmp/${FDB_CLIENTS_PKG} /tmp/${FDB_SERVER_PKG}

RUN for dir in ${FDB_USER_DIRS}; do mv ${dir} ${dir}.default; done

CMD sed -i "s/127.0.0.1/$(grep $(hostname) /etc/hosts | awk '{print $1}')/" /etc/foundationdb.default/fdb.cluster && \
    for dir in ${FDB_USER_DIRS}; do cp -r --no-clobber ${dir}.default/* ${dir}; done && \
    groupmod -g ${FDB_GID} --non-unique foundationdb && \
    usermod -g ${FDB_GID} -u ${FDB_UID} --non-unique foundationdb && \
    chown -R foundationdb:foundationdb ${FDB_USER_DIRS} && \
    /usr/lib/foundationdb/fdbmonitor
