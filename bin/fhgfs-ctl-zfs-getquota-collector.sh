#!/bin/bash

get_fhgfs_storage_nodes() {
  fhgfs-ctl --listnodes --nodetype=storage | cut -d ' ' -f 1 | tr "\\n" " "
}

exec_cmd() {
  local cmd="$1"
  echo "Executing: ${cmd}"
  eval $cmd
}

HOSTS="$@"
[ -z "$HOSTS" ] && HOSTS=$(get_fhgfs_storage_nodes)

CONF="/etc/defaults/fhgfs-ctl-zfs-getquota.conf"

if [ -f $CONF ]; then
  source $CONF
fi

ZFS_FILESYSTEM=${ZFS_FILESYSTEM:='tank'}
OUTPUT_DIR=${OUTPUT_DIR:='/tmp'}

BASENAME=$(basename $0)
NAME="${BASENAME%.*}"

USERSPACE_OUTPUT="${OUTPUT_DIR}/${NAME}.userspace"
GROUPSPACE_OUTPUT="${OUTPUT_DIR}/${NAME}.groupspace"

exec_cmd ": > ${USERSPACE_OUTPUT}"
exec_cmd ": > ${GROUPSPACE_OUTPUT}"

for host in $HOSTS; do
  exec_cmd "ssh -nq root@${host} 'zfs userspace -n -H -p -o name,used -s name ${ZFS_FILESYSTEM} 2>/dev/null' >>${USERSPACE_OUTPUT}"
  exec_cmd "ssh -nq root@${host} 'zfs groupspace -n -H -p -o name,used -s name ${ZFS_FILESYSTEM} 2>/dev/null' >>${GROUPSPACE_OUTPUT}"
done

exit 0
