# Official FoundationDB Docker image

## Base Images

* Ubuntu `18.04`, `16.04`
* CentOS `6.9`
* Debian `9.4` (not officially supported)

## Build

This is for development/testing purposes, official Docker builds are available on [Docker Hub](https://hub.docker.com/r/apple/foundationdb/).

```bash
git clone https://github.com/apple/foundationdb
docker build -t foundationdb:5.1.7-ubuntu-18.04 foundationdb/docker/ubuntu/18.04
```

**Note:** Replace `ubuntu-18.04` and `ubuntu/18.04` with the version that you are building.


## Usage

This will start a Docker container running FoundationDB.

```bash
docker run -d \
  -e FDB_UID=$(id -u) \
  -e FDB_GID=$(id -g) \
  --mount type=volume,src=fdb4500-example-data,dst=/var/lib/foundationdb
  --mount type=bind,src=$(pwd)/etc,dst=/etc/foundationdb \
  --mount type=bind,src=$(pwd)/log,dst=/var/log/foundationdb \
  --name fdb-example \
  -p 127.0.0.1:4500:4500 \
  foundationdb:5.1.7-ubuntu-18.04
```

* `--mount type=volume,src=fdb-example-data,dst=/var/lib/foundationdb` sets the name of the volume containing the database state to `fdb-example-data`.
* `--mount type=bind,src=$(pwd)/etc,dst=/etc/foundationdb` copies the default configuration to `./etc` or uses the existing files.
* `--mount type=bind,src=$(pwd)/log,dst=/var/log/foundationdb` writes log files to `./log`.
* `--name fdb-example` sets the name of the container to `fdb-example`.
* `-p 127.0.0.1:4500:4500` binds `localhost:4500/tcp` to the container's `4500/tcp`, for local access.

You should be able to connect to the FoundationDB container at `localhost:4500` with the `fdb.cluster` file in `./etc`.

## Usage with `docker-compose`

You can use this Docker container with `docker-compose`. Example:

```yaml
version: '3'

services:

  ... your app here ...

  fdb:
    image: foundationdb:5.1.7-ubuntu-18.04
    volumes:
      - ./etc:/etc/foundationdb
      - ./log:/var/log/foundationdb
```

Your app can now connect to FoundationDB at `fdb:4500` with the `fdb.cluster` file available in `./etc`.

**Warning:** `docker-compose` is not suitable for production environments.

## Simulate a fault-tolerant setup

### Create accessible directories

```bash
mkdir -p fdb450{0,1,2}-example/{etc,log}
```

### Create a network for communication

```bash
docker network create fdb-example
```

### Create and start the first container

```bash
docker run -d \
  -e FDB_UID=$(id -u) \
  -e FDB_GID=$(id -g) \
  --mount type=volume,src=fdb4500-example-data,dst=/var/lib/foundationdb \
  --mount type=bind,src=$(pwd)/fdb4500-example/etc,dst=/etc/foundationdb \
  --mount type=bind,src=$(pwd)/fdb4500-example/log,dst=/var/log/foundationdb \
  --net fdb-example \
  --name fdb4500-example \
  foundationdb:5.1.7-ubuntu-18.04
```

### Configure unique IDs for the remaining containers

```bash
cat <<'EOF' >fdb4501-example/etc/foundationdb.conf
[fdbmonitor]
user = foundationdb
group = foundationdb

[general]
restart_delay = 60
cluster_file = /etc/foundationdb/fdb.cluster

[fdbserver]
command = /usr/sbin/fdbserver
public_address = auto:$ID
listen_address = public
datadir = /var/lib/foundationdb/data/$ID
logdir = /var/log/foundationdb

[fdbserver.4501]

[backup_agent]
command = /usr/lib/foundationdb/backup_agent/backup_agent

[backup_agent.2]
EOF

cat <<'EOF' >fdb4502-example/etc/foundationdb.conf
[fdbmonitor]
user = foundationdb
group = foundationdb

[general]
restart_delay = 60
cluster_file = /etc/foundationdb/fdb.cluster

[fdbserver]
command = /usr/sbin/fdbserver
public_address = auto:$ID
listen_address = public
datadir = /var/lib/foundationdb/data/$ID
logdir = /var/log/foundationdb

[fdbserver.4502]

[backup_agent]
command = /usr/lib/foundationdb/backup_agent/backup_agent

[backup_agent.3]
EOF
```

### Copy `fdb.cluster` into the remaining containers

```bash
cp fdb4500-example/etc/fdb.cluster fdb4501-example/etc
cp fdb4500-example/etc/fdb.cluster fdb4502-example/etc
```

### Create and start the remaining containers

```bash
docker run -d \
  -e FDB_UID=$(id -u) \
  -e FDB_GID=$(id -g) \
  --mount type=volume,src=fdb4501-example-data,dst=/var/lib/foundationdb \
  --mount type=bind,src=$(pwd)/fdb4501-example/etc,dst=/etc/foundationdb \
  --mount type=bind,src=$(pwd)/fdb4501-example/log,dst=/var/log/foundationdb \
  --net fdb-example \
  --name fdb4501-example \
  foundationdb:5.1.7-ubuntu-18.04

docker run -d \
  -e FDB_UID=$(id -u) \
  -e FDB_GID=$(id -g) \
  --mount type=volume,src=fdb4502-example-data,dst=/var/lib/foundationdb \
  --mount type=bind,src=$(pwd)/fdb4502-example/etc,dst=/etc/foundationdb \
  --mount type=bind,src=$(pwd)/fdb4502-example/log,dst=/var/log/foundationdb \
  --net fdb-example \
  --name fdb4502-example \
  foundationdb:5.1.7-ubuntu-18.04
```

### Reconfigure cluster replication

```bash
docker exec fdb4500-example fdbcli --exec "configure double memory"
```

### Reconfigure coordinators

```bash
docker exec fdb4500-example fdbcli --exec "coordinators auto"
```

### Wait for reinitialization to complete

```bash
docker exec fdb4500-example fdbcli --exec "status"
```

or, using watch:

```bash
watch -n0.5 docker exec fdb4500-example fdbcli --exec "status"
```

### Clean up and remove example data

```bash
docker stop fdb450{0,1,2}-example
docker rm fdb450{0,1,2}-example
docker volume rm fdb450{0,1,2}-example-data
docker network rm fdb-example
rm -r fdb450{0,1,2}-example
```

Check out the [documentation](https://apple.github.io/foundationdb/administration.html) to learn more about administering your own cluster.
