#!/usr/bin/env bash

# Create the environment file for crond
printenv | sed 's/^\([a-zA-Z0-9_]*\)=\(.*\)$/export \1="\2"/g' | grep -E "^export RCLONE" >/cron/rclone.env

source /cron/rclone.env

function rclone_copy() {
  (
    flock -n 200 || exit 1
    sync_command="rclone copy ${RCLONE_CROND_SOURCE_PATH} ${RCLONE_CROND_DESTINATION_PATH}"

    if [ "${RCLONE_SYNC_COMMAND}" ]; then
      sync_command="${RCLONE_SYNC_COMMAND}"
    else
      if [[ -z "${RCLONE_CROND_SOURCE_PATH}" ]] || [[ -z "${RCLONE_CROND_DESTINATION_PATH}" ]]; then
        echo "Error: A RCLONE PATH environment variable was not set or passed to the container. Please review your RCLONE source/destination paths."
        exit 1
      fi
    fi

    echo "Executing => ${sync_command}"
    eval "${sync_command}" || send
  ) 200>/run/rclone.lock
}

function rclone_move() {
  (
    flock -n 200 || exit 1
    sync_command="rclone move ${RCLONE_CROND_SOURCE_PATH} ${RCLONE_CROND_DESTINATION_PATH}"
    if [ "${RCLONE_SYNC_COMMAND}" ]; then
      sync_command="${RCLONE_SYNC_COMMAND}"
    else
      if [[ -z "${RCLONE_CROND_SOURCE_PATH}" ]] || [[ -z "${RCLONE_CROND_DESTINATION_PATH}" ]]; then
        echo "Error: A RCLONE PATH environment variable was not set or passed to the container. Please review your RCLONE source/destination paths."
        exit 1
      fi
    fi
    echo "Executing => ${sync_command}"
    eval "${sync_command}" || send
  ) 200>/run/rclone.lock
}

function foldersize() {
  if [[ -z "${RCLONE_CROND_SOURCE_PATH}" ]] || [[ -z "${RCLONE_CROND_SOURCE_SIZE}" ]]; then
    echo "INFO: A local folder path and/or size has not been set. Not using folder monitor"
  else
    SIZE=$(/usr/bin/du -s ${RCLONE_CROND_SOURCE_PATH} | /usr/bin/awk '{print $1}')
    MBSIZE=$((SIZE / 1024))
    echo "${RCLONE_CROND_SOURCE_PATH} is $MBSIZE MB"
    if [[ ${MBSIZE} -gt $((${RCLONE_CROND_SOURCE_SIZE})) ]]; then
      rclone_move
    fi
  fi
}

function run() {
  echo "sfsfsfs"
  rclone_copy
  foldersize
}

"$@"
