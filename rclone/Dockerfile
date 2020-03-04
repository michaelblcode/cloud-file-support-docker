FROM rclone/rclone:latest AS rclone-server
RUN set -x \
    && apk add --no-cache --virtual .persistent_deps bash

COPY entrypoint.sh /entrypoint.sh
COPY rclone.sh /rclone.sh
COPY rcron.sh /usr/bin/rcron
COPY config/rclone.conf /config/rclone/

RUN chmod +x /entrypoint.sh /usr/bin/rcron

ENTRYPOINT [ "bash", "/entrypoint.sh" ]
CMD [ "" ]
