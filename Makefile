prefix := /usr
sysconfdir := /etc
sbindir := $(prefix)/sbin
datadir := $(prefix)/share
mandir := $(datadir)/man

_default:
	@echo "No default. Try 'make install'"

install:
	install -d $(DESTDIR)$(sysconfdir)/default
	install -m 0644 etc/fhgfs-ctl-zfs-getquota.conf $(DESTDIR)$(sysconfdir)/default/fhgfs-ctl-zfs-getquota.conf
	install -d $(DESTDIR)$(sysconfdir)/cron.hourly
	install -m 0644 etc/fhgfs_quota.cron $(DESTDIR)$(sysconfdir)/cron.hourly/fhgfs_quota
	install -d $(DESTDIR)$(datadir)/fhgfs-ctl-zfs-getquota
	install bin/fhgfs-ctl-zfs-getquota-collector.sh $(DESTDIR)$(datadir)/fhgfs-ctl-zfs-getquota/fhgfs-ctl-zfs-getquota-collector
	install bin/zfs_get_quota.rb $(DESTDIR)$(datadir)/fhgfs-ctl-zfs-getquota/zfs_get_quota
