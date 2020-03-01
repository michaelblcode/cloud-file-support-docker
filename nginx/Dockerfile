FROM nginx:latest
COPY ./config/nginx.conf /etc/nginx/nginx.conf
COPY ./config/.htpasswd /opt/nginx/.htpasswd
RUN mkdir -p /tmp/nginx
