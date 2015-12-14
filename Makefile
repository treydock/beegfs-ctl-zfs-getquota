prefix := /usr
sysconfdir := /etc
sbindir := $(prefix)/sbin
datadir := $(prefix)/share
mandir := $(datadir)/man

_default:
	@echo "No default. Try 'make install'"

install:
	test -d $(DESTDIR)$(sysconfdir)/default || install -d $(DESTDIR)$(sysconfdir)/default
	install -m 0644 etc/beegfs-ctl-zfs-getquota.conf $(DESTDIR)$(sysconfdir)/default/beegfs-ctl-zfs-getquota.conf
	test -d $(DESTDIR)$(sysconfdir)/cron.hourly || install -d $(DESTDIR)$(sysconfdir)/cron.hourly
	install -m 0755 etc/beegfs_quota.cron $(DESTDIR)$(sysconfdir)/cron.hourly/beegfs_quota
	install -d $(DESTDIR)$(datadir)/beegfs-ctl-zfs-getquota
	install -m 0755 bin/beegfs-ctl-zfs-getquota-collector.sh $(DESTDIR)$(datadir)/beegfs-ctl-zfs-getquota/beegfs-ctl-zfs-getquota-collector
	install -m 0755 bin/zfs_get_quota.py $(DESTDIR)$(datadir)/beegfs-ctl-zfs-getquota/zfs_get_quota
