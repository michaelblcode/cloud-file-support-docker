#!/usr/bin/env bash

# Create the environment file for crond
printenv | sed 's/^\([a-zA-Z0-9_]*\)=\(.*\)$/export \1="\2"/g' | grep -E "^export RCLONE" >/cron/rclone.env

source /cron/rclone.env

function rclone_copy() {
  (
    flock -n 200 || exit 1

    sync_list=/config/rclone/sync_list.conf
    while IFS= read -r line; do
      IFS=','
      read -ra path <<<"$line"

      src=${path[0]}
      dst="${RCLONE_RSYNC_PATH}${path[1]}"

      sync_command="rclone copy $src $dst"

      if [[ -z "$src" ]] || [[ -z "$dst" ]]; then
        echo "Error: src and/or dst are/is empty. Please review your sync_list.conf file."
        exit 1
      fi

      echo "Excuting - $sync_command"
      eval "$sync_command"
    done <$sync_list
  ) 200>/run/rclone.lock
}

function rclone_move() {
  (
    flock -n 200 || exit 1

    sync_command="rclone copy $1 $2"

    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
      echo "Error: src and/or dst are/is empty. Please review your sync_list.conf file."
      exit 1
    fi

    echo "Excuting - $sync_command"
    eval "$sync_command"
  ) 200>/run/rclone.lock
}

function foldersize() {
  sync_list=/config/rclone/sync_list.conf
  while IFS= read -r line; do
    IFS=','
    read -ra path <<<"$line"
    src=${path[0]}
    dst="${RCLONE_RSYNC_PATH}${path[1]}"

    if [[ -z "${src}" ]]; then
      echo "INFO: source folder hasn't been set"
    else
      SIZE=$(/usr/bin/du -s ${src} | /usr/bin/awk '{print $1}')
      MBSIZE=$((SIZE / 1024))
      echo "${src} is $MBSIZE MB"
      if [[ ${MBSIZE} -gt $((${RCLONE_CROND_SOURCE_SIZE})) ]]; then
        rclone_move "${src}" "${dst}"
      fi
    fi
  done <$sync_list
}

function run() {
  rclone_copy
  foldersize
}

"$@"
