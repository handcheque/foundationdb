# Official FoundationDB Docker image

## What underlaying OSs are available?

* Ubuntu `18.04`, `16.04`
* CentOS `6.9`
* Debian `9.4` (not officially supported)


## Build

This is for development/testing purposes, official Docker builds are available on the Docker Hub.

```bash
git clone https://github.com/apple/foundationdb
docker build -t foundationdb:5.1.7-ubuntu-18.04 foundationdb/docker/ubuntu/18.04
```

Note: replace `ubuntu-18.04` and `ubuntu/18.04` with whatever version you are building.


## Usage

This will get you a Docker container running FoundationDB.

```bash
docker run -d \
  -e FDB_UID=$(id -u) \
  -e FDB_GID=$(id -g) \
  -v $(pwd)/conf:/etc/foundationdb \
  -v $(pwd)/logs:/var/log/foundationdb \
  -v $(pwd)/data:/var/lib/foundationdb/data \
  -p 127.0.0.1:4500:4500 \
  foundationdb:5.1.7-ubuntu-18.04
```

* `-v $(pwd)/conf:/etc/foundationdb`, puts the configuration files on `./conf`.
* `-v $(pwd)/logs:/var/log/foundationdb`, puts the logs on `./logs`.
* `-v $(pwd)/data:/var/lib/foundationdb/data`, persistently stores database data on `./data`.
* `-p 127.0.0.1:4500:4500`, binds `localhost:4500/tcp` to the container's `4500/tcp`, for local access.

You should be able to connect to the FoundationDB container at `localhost:4500` with the `fdb.cluster` file in `./conf`.

## Usage with `docker-compose`

You can use this Docker container with `docker-compose`. Example:

```yaml
version: '3'

services:

  ... your app here ...

  db:
    image: foundationdb:5.1.7-ubuntu-18.04
    volumes:
      - ./conf:/etc/foundationdb
      - ./logs:/var/log/foundationdb
      - ./data:/var/lib/foundationdb/data
```

Your app can now connect to FoundationDB at `db:4500` with the `fdb.cluster` file available in `./conf`.

Warning: `docker-compose` is not suitable for production environments.

## Simulate a fault-tolerant setup

### Create configuration directories

```bash
mkdir -p fdb450{0,1,2}-example/conf
```

This ensures that the correct user and group permissions are set, so that they can be quickly and safely removed when finished.

### Create a network for communication
```bash
docker network create fdb-example
```

### Create and start the first container
```bash
docker run -d \
  -e FDB_UID=$(id -u) \
  -e FDB_GID=$(id -g) \
  -v $(pwd)/fdb4500-example/conf:/etc/foundationdb \
  -v $(pwd)/fdb4500-example/logs:/var/log/foundationdb \
  -v $(pwd)/fdb4500-example/data:/var/lib/foundationdb/data \
  --net fdb-example \
  --name fdb4500-example \
  foundationdb:5.1.7-ubuntu-18.04
```

### Configure unique IDs for the remaining containers

```bash
cat <<'EOF' >fdb4501-example/conf/foundationdb.conf
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
EOF

cat <<'EOF' >fdb4502-example/conf/foundationdb.conf
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
EOF
```

### Copy `fdb.cluster` into the remaining containers

```bash
cp fdb4500-example/conf/fdb.cluster fdb4501-example/conf
cp fdb4500-example/conf/fdb.cluster fdb4502-example/conf
```

### Create and start the remaining containers
```bash
docker run -d \
  -e FDB_UID=$(id -u) \
  -e FDB_GID=$(id -g) \
  -v $(pwd)/fdb4501-example/conf:/etc/foundationdb \
  -v $(pwd)/fdb4501-example/logs:/var/log/foundationdb \
  -v $(pwd)/fdb4501-example/data:/var/lib/foundationdb/data \
  --net fdb-example \
  --name fdb4501-example \
  foundationdb:5.1.7-ubuntu-18.04

docker run -d \
  -e FDB_UID=$(id -u) \
  -e FDB_GID=$(id -g) \
  -v $(pwd)/fdb4502-example/conf:/etc/foundationdb \
  -v $(pwd)/fdb4502-example/logs:/var/log/foundationdb \
  -v $(pwd)/fdb4502-example/data:/var/lib/foundationdb/data \
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
watch -n0.5 docker exec fdb4500-example fdbcli --exec "status"
```

### Clean up and remove example data

```bash
docker stop fdb450{0,1,2}-example
docker rm fdb450{0,1,2}-example
docker network rm fdb-example
rm -r fdb450{0,1,2}-example
```

Check out the [documentation](https://apple.github.io/foundationdb/administration.html) to learn more about administering your own cluster.