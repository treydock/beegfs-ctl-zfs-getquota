#!/bin/bash

get_beegfs_storage_nodes() {
  beegfs-ctl --listnodes --nodetype=storage | cut -d ' ' -f 1 | tr "\\n" " "
}

exec_cmd() {
  local cmd="$1"
  echo "Executing: ${cmd}"
  eval $cmd
}

HOSTS="$@"
[ -z "$HOSTS" ] && HOSTS=$(get_beegfs_storage_nodes)

CONF="/etc/default/beegfs-ctl-zfs-getquota.conf"

if [ -f $CONF ]; then
  source $CONF
fi

ZFS_FILESYSTEM=${ZFS_FILESYSTEM:='tank'}
COLLECTOR_OUTPUT_PREFIX=${COLLECTOR_OUTPUT_PREFIX:='/tmp/beegfs-ctl-zfs-getquota-collector'}
USERSPACE_OUTPUT="${COLLECTOR_OUTPUT_PREFIX}.userspace"
GROUPSPACE_OUTPUT="${COLLECTOR_OUTPUT_PREFIX}.groupspace"

exec_cmd ": > ${USERSPACE_OUTPUT}"
exec_cmd ": > ${GROUPSPACE_OUTPUT}"

for host in $HOSTS; do
  # Get storeStorageDirectory value from beegfs-storage.conf
  storeStorageDirectory=$(ssh -nq root@${host} "awk '/^storeStorageDirectory/{print \$NF }' /etc/beegfs/beegfs-storage.conf")
  # Determine if storeStorageDirectory is a mounted ZFS filesystem
  filesystem=$(ssh -nq root@${host} "grep '${storeStorageDirectory}' /proc/mounts | awk '{ print \$1 }'")
  if [ -z "$filesystem" ]; then
    QUERY_FILESYSTEM=${ZFS_FILESYSTEM}
  else
    QUERY_FILESYSTEM=${filesystem}
  fi
  exec_cmd "ssh -nq root@${host} 'zfs userspace -n -H -p -o name,used -s name ${QUERY_FILESYSTEM} 2>/dev/null' >>${USERSPACE_OUTPUT}"
  exec_cmd "ssh -nq root@${host} 'zfs groupspace -n -H -p -o name,used -s name ${QUERY_FILESYSTEM} 2>/dev/null' >>${GROUPSPACE_OUTPUT}"
done

exit 0
