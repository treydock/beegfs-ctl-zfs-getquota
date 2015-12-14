version = 0.0.1
relversion := 1
prefix := /usr
sysconfdir := /etc
sbindir := $(prefix)/sbin
libexecdir := $(prefix)/libexec
mandir := $(libexecdir)/man
pkgname := beegfs-ctl-zfs-getquota-$(version)
pkgdir := $(shell pwd)/pkg


_default:
	@echo "No default. Try 'make install'"

install:
	test -d $(DESTDIR)$(sysconfdir)/default || install -d $(DESTDIR)$(sysconfdir)/default
	install -m 0644 etc/beegfs-ctl-zfs-getquota.conf $(DESTDIR)$(sysconfdir)/default/beegfs-ctl-zfs-getquota.conf
	test -d $(DESTDIR)$(sysconfdir)/cron.hourly || install -d $(DESTDIR)$(sysconfdir)/cron.hourly
	install -m 0755 etc/beegfs_quota.cron $(DESTDIR)$(sysconfdir)/cron.hourly/beegfs_quota
	install -d $(DESTDIR)$(libexecdir)/beegfs-ctl-zfs-getquota
	install -m 0755 bin/beegfs-ctl-zfs-getquota-collector.sh $(DESTDIR)$(libexecdir)/beegfs-ctl-zfs-getquota/beegfs-ctl-zfs-getquota-collector
	install -m 0755 bin/zfs_get_quota.py $(DESTDIR)$(libexecdir)/beegfs-ctl-zfs-getquota/zfs_get_quota

package:
	mkdir -p $(pkgdir)
	git archive --format tar --prefix $(pkgname)/ HEAD | gzip > $(pkgdir)/$(pkgname).tar.gz

rpm: package
	rpmbuild --define "_topdir $(pkgdir)" \
	--define "_builddir %{_topdir}" \
	--define "_rpmdir %{_topdir}" \
	--define "_srcrpmdir %{_topdir}" \
	--define "_specdir %{_topdir}" \
 	--define "_sourcedir  %{_topdir}" \
	--define "version $(version)" \
	--define "relversion $(relversion)" \
	-ba beegfs-ctl-zfs-getquota.spec
