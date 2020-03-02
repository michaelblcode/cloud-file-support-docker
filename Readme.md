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
# type your password twice

cat .htpasswd
```

```
foo:xOVvNJC532.Pe3
```

Add another user bar

```
echo -n 'bar:' >> .htpasswd
openssl passwd -apr1 >> .htpasswd
#type your password twice
cat .htpasswd
```

```
foo:xOVvNJC532.Pe3
bar:$apr1$/hbFh44e$D5RZ91WBHCQlBymeuMCIv.
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

Tset

> url: http://localhost:5000/foo-permitted-file.o
> url: http://localhost:5000/bar-permitted-file1.o
