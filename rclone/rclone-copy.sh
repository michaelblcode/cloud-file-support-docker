SYNC_LIST="./config/sync_list.conf"
LIST_STRING=`cat $SYNC_LIST`
IFS=';'
read -ra LIST <<< $LIST_STRING
for i in "${LIST[@]}"; do
  echo "$i"
done
