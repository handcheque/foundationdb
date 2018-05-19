FROM centos:7.4.1708

ARG FDB_VERSION="5.1.7"
ARG FDB_RPM_RELEASE="1"

ARG FDB_PKG_URL="https://www.foundationdb.org/downloads/${FDB_VERSION}/rhel6/installers"
ARG FDB_CLIENTS_PKG="foundationdb-clients-${FDB_VERSION}-${FDB_RPM_RELEASE}.el6.x86_64.rpm"
ARG FDB_SERVER_PKG="foundationdb-server-${FDB_VERSION}-${FDB_RPM_RELEASE}.el6.x86_64.rpm"
ARG FDB_USER_DIRS="/etc/foundationdb /var/log/foundationdb /var/lib/foundationdb"

ENV FDB_USER_DIRS="$FDB_USER_DIRS"
ENV FDB_UID="1000"
ENV FDB_GID="1000"

ADD $FDB_PKG_URL/$FDB_CLIENTS_PKG /tmp/$FDB_CLIENTS_PKG
ADD $FDB_PKG_URL/$FDB_SERVER_PKG /tmp/$FDB_SERVER_PKG

RUN yum install -y python initscripts && \
    rm -rf /var/cache/yum 
RUN rpm -Uvh /tmp/$FDB_CLIENTS_PKG /tmp/$FDB_SERVER_PKG && \
    rm /tmp/$FDB_CLIENTS_PKG /tmp/$FDB_SERVER_PKG

RUN rm /var/log/foundationdb/trace.*.1.xml && \
    for DIR in $FDB_USER_DIRS; do mv $DIR $DIR.default; done

COPY entrypoint.sh /usr/local/bin/

VOLUME ["/var/lib/foundationdb"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/lib/foundationdb/fdbmonitor"]
