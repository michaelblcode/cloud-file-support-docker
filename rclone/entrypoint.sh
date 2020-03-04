set -o nounset
set -o pipefail

#---------------------------------------------------------------------
# run services
#---------------------------------------------------------------------

function run() {
  cat /cron/crontab.conf | crontab - && crontab -l
  rcron start
}

run
exec "$@"
