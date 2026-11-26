AUTOMAKE_OPTIONS = subdir-objects
include $(srcdir)/pecan-build.mk

pkgdir = $(libdir)/purple-$(PURPLE_MAJOR_VERSION)
EXTRA_DIST = Makefile.mingw pecan-build.mk COPYING AUTHORS README.md \
	pidgin-copyright win32/resource.rc ext/libmspack/COPYING.LIB

if STATIC_MSN
noinst_LTLIBRARIES = libmsn.la
msn_static_flags = -DSTATIC_PECAN -Dpurple_init_msn_pecan_plugin=purple_init_msn_plugin
else
pkg_LTLIBRARIES = libmsn.la
endif

libmsn_la_SOURCES = $(PECAN_SOURCES) $(pecan_headers)
libmsn_la_LDFLAGS = -module -avoid-version
libmsn_la_LIBADD = $(MSN_GIO_LIBS) -lm
libmsn_la_CPPFLAGS = $(AM_CPPFLAGS) $(msn_static_flags)

AM_CPPFLAGS = -I$(srcdir) -I$(top_srcdir)/libpurple -I$(top_builddir)/libpurple \
	$(PECAN_DEFINES) $(MSN_GIO_CFLAGS)
