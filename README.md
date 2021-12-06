# DarkflameServer Dockerfile

# !!! THIS DOESN'T CURRENTLY WORK !!!

## How to set up

1. Install Docker (Desktop)
2. Get an UNPACKED Lego Universe Client
3. Copy the Client and put it into this Folder named "Client"

## How to Build and Start the Image

### Building

```sh
docker build -t darkflame .
```

### Starting

```sh
docker run --rm -dp 3306:3306 -p 1000-1050:1000-1050 -p 2000-2050:2000-2050 -p 3000-3050:3000-3050 darkflame
```

### Connecting to it

#### Get Container ID: (Copy the cryptic looking thing in the Start)

```sh
docker ps
```

#### Running a BASH on it

```sh
docker exec -it [CONTAINERID] /bin/bash
```

## Problems

1. The Server sometimes just dies with the Error Message:

```
Destroying MySQL connection!
[06-12-21 21:12:20] [Test]: Quitting
```

2. You cannot connect from the outside into the Server even though all Ports are exposed and mapped
