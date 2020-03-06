# Could File Support - Docker

It's a docker-based project, download-only file server that is authenticated, restricted and configurable access (command line interface only) to cloud files from other sources.

## Getting Started

These instructions will get you a copay of the project up and running on your local machine for development and testing purpose.

### Prerequisites

It requires [docker](https://www.docker.com/products/docker-desktop) and docker-compose

## Running the tests

### File Download Test

Compose nginx docker image on root using docker-compose command.

```
docker-compose up
docker-compose up -d
```

Compose file
```
nginx:
  build: nginx/.
  ports:
    - "5000:80"
  volumes:
    - "./files:/www/data/files"
rclone:
  build: rclone/.
```

Nginx `Dockerfile`
```
FROM nginx:latest
COPY ./config/nginx.conf /etc/nginx/nginx.conf
COPY ./config/.htpasswd /opt/nginx/.htpasswd
RUN mkdir -p /tmp/nginx
```

Nginx configuration
```
events {
  worker_connections 1024;
}

http {
  log_format access_user_log '[$time_local] $remote_user - $uri';

  server {
    listen 80;

    autoindex on;
    autoindex_exact_size off;
    autoindex_localtime on;

    auth_basic "Restricted site";
    auth_basic_user_file /opt/nginx/.htpasswd;

    root /www/data;

    location / {
      alias /www/data/files/;
      access_log /tmp/nginx/nginx-log.log access_user_log;

      try_files $remote_user$uri \
                $remote_user$uri/
                =404;
    }

    sendfile off;

    ##
    # Gzip Settings
    #

    gzip on;
    gzip_min_length 1000;
    gzip_proxied no-cache no-store private expired auth;
    gunzip on;
  }
}
```

Prepare some user credentials to enter into `.htpasswd`.

```
echo -n 'foo:' >> .htpasswd
openssl passwd >> .htpasswd
# type your password twice -> aaa

cat .htpasswd
```

```
foo:ImMLrG54rX5.Y
```

Add another user bar

```
echo -n 'bar:' >> .htpasswd
openssl passwd -apr1 >> .htpasswd
#type your password twice -> bbb
cat .htpasswd
```

```
foo:ImMLrG54rX5.Y
bar:$apr1$SZKrOd6s$hPJP3fAktuShz0RKSveZ9/
```

Prepare dummy files to download.

```
files/
|-- foo/
|   |-- foo-permitted-file.o
|   |-- foo-permitted-file1.o
|-- bar/
|   |-- bar-permitted-file.o
|   |-- bar-permitted-file1.o
```

Tset with `curl`

> curl -u foo:aaa -O "http://server_ip:5000/foo-permitted-file.o"<br/>curl -u bar:bbb -o bar-file1.0 "http://server_ip:5000/bar-permitted-file1.o" 

Test with `wget`

>wget --user foo --password aaa "http://server_ip:5000/foo-permitted-file.o"<br/>wget --user bar --password bbb -O bar-file1.o "http://server_ip:5000/foo-permitted-file1.0"


### Testing `Crond` Inside Docker

#### Step1: `crontab.conf` config

Running `crond` requires a proper configuration file. You can easily add a crontab config file and have the container use it.
A `crontab.conf` should look something like this.

```
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
* * * * * /rclone.sh run 2>&1
```

#### Step2: Mount your `crontab.conf` config

You can use `COPY` in `Dockerfile` to mount into the container.

```
COPY cron/crontab.conf /cron/
```

#### Step3: `docker-compose up`

With current config, cron job performs every minute. You can confirm it on console.

### Testing `Rclone`

#### Step1: Rclone remote test

You should run below command to switch console into of Docker container.

```
$ docker exec -it CONTAINER bash
bash-5.0#
```

Here you can run `rclone` manually to check it works well.

```
rclone lsd [remote]:
```

#### Step2: `rclone.conf` config

Let's test with SFTP. Make sure you can handle a sftp server and have a valid credentials to access. You can use [MacOS](https://chainsawonatireswing.com/2012/08/09/how-to-set-up-an-sftp-server-on-a-mac-then-enable-a-friend-to-upload-files-to-it-from-their-iphone-ipad-or-other-idevice/) / [Linux](https://linuxconfig.org/how-to-setup-sftp-server-on-ubuntu-18-04-bionic-beaver-with-vsftpd) / [Windows](https://www.windowscentral.com/how-set-and-manage-ftp-server-windows-10) as sftp server.

Config 2 remote providers

```
[sftp1]
type = sftp
host = sftp.example1.com
user = remote_user1
port = 22 # or 443
pass = password1

[sftp2]
type = sftp
host = sftp.example2.com
user = remote_user2
port = 22 # or 443
pass = password2
```

Note that password should be obscured. Please run `rclone obscure {PASSWORD}` and use the encoded string as `pass`.

#### Step3: `/rclone.sh` & `sync_list.conf` config

Running /rclone.sh
```
/rclone.sh run
```

`rclone.sh` is running with configuration something like following.

```
sftp1:directory1/folder/report_1.zip,foo/directory1/folder/
```
By above configuration
```
rclone copy sftp1:directory1/folder/report_1.zip foo/directory1/folder/
```
If there is not `foo/directory1/folder`, it makes new folder and copies file.
If the source has been changed, it overwrites to update the existing file.

> Note that the source path should be valid.
