FROM nginx:latest AS nginx-server
COPY ./config/nginx.conf /etc/nginx/nginx.conf
COPY ./config/.htpasswd /opt/nginx/.htpasswd
RUN mkdir -p /tmp/nginx
