AC_PREREQ([2.67])
AC_INIT([gnome-contacts],[3.25.4],[http://bugzilla.gnome.org/enter_bug.cgi?product=gnome-contacts])
AC_CONFIG_SRCDIR([src/main.vala])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])
AM_INIT_AUTOMAKE([foreign tar-ustar dist-xz no-dist-gzip -Wno-portability])

# Enable silent rules is available
AM_SILENT_RULES([yes])

GETTEXT_PACKAGE=gnome-contacts
AC_DEFINE_UNQUOTED([GETTEXT_PACKAGE], ["$GETTEXT_PACKAGE"], [Gettext Package])
AC_SUBST(GETTEXT_PACKAGE)

AM_GNU_GETTEXT_VERSION([0.19.7])
AM_GNU_GETTEXT([external])

LT_INIT
AC_PROG_CC
AM_PROG_VALAC([0.24.0])
AC_PROG_INSTALL
AC_PATH_PROG([GLIB_GENMARSHAL],[glib-genmarshal])
AC_PATH_PROG([GLIB_MKENUMS],[glib-mkenums])
AC_PATH_PROG([GLIB_COMPILE_RESOURCES],[glib-compile-resources])
GLIB_GSETTINGS

GLIB_REQUIRED=2.44.0
AC_SUBST(GLIB_REQUIRED)

pkg_modules="gtk+-3.0 >= 3.22.0
	     glib-2.0 >= $GLIB_REQUIRED
	     gmodule-export-2.0
	     gnome-desktop-3.0
	     gio-unix-2.0 >= $GLIB_REQUIRED
	     folks >= 0.11.4
	     folks-telepathy
	     folks-eds
	     telepathy-glib >= 0.22.0
	     libebook-1.2 >= 3.13.90
	     libedataserver-1.2 >= 3.13.90
	     libedataserverui-1.2 >= 3.13.90
	     goa-1.0
	     gee-0.8
	     champlain-0.12
	     clutter-gtk-1.0
	     geocode-glib-1.0 >= 3.15.3
	     "
PKG_CHECK_MODULES(CONTACTS, [$pkg_modules])

CONTACTS_PACKAGES="--pkg gtk+-3.0 --pkg gio-2.0 --pkg gio-unix-2.0 --pkg gnome-desktop-3.0 --pkg folks --pkg folks-telepathy --pkg folks-eds --pkg clutter-1.0 --pkg clutter-gtk-1.0 --pkg champlain-0.12 --pkg geocode-glib-1.0"

# Optional dependency for the user accounts panel
AC_ARG_WITH([cheese],
            AS_HELP_STRING([--with-cheese], [enable cheese webcam support]),,
            with_cheese=auto)

if test x"$with_cheese" != x"no" ; then
   PKG_CHECK_MODULES(CHEESE, cheese-gtk >= 3.3.91 cheese, [have_cheese=yes], [have_cheese=no])
   if test x${have_cheese} = xyes; then
     AC_DEFINE(HAVE_CHEESE, 1, [Define to 1 to enable cheese webcam support])
     CONTACTS_PACKAGES+=" --pkg cheese --pkg cheese-gtk"
   fi
   if test x${with_cheese} = xyes && test x${have_cheese} = xno; then
     AC_MSG_ERROR([Cheese configured but not found])
   fi
else
   have_cheese=no
fi
AM_CONDITIONAL(BUILD_CHEESE, test x${have_cheese} = xyes)


AC_SUBST(CONTACTS_PACKAGES)

#############
# Resources #
#############

GLIB_COMPILE_RESOURCES=`$PKG_CONFIG --variable glib_compile_resources gio-2.0`
AC_SUBST(GLIB_COMPILE_RESOURCES)

#################
# Documentation #
#################

AC_ARG_ENABLE([man-pages],
              [AS_HELP_STRING([--disable-man-pages],
                              [disable building man pages])])
AS_IF([test "x$enable_man_pages" != "xno"],
      [AC_PATH_PROG([XSLTPROC], [xsltproc])
       AS_IF([test "xac_cv_path_XSLTPROC" = "x"], [have_xsltproc=no],
             [have_xsltproc=yes])
       JH_CHECK_XML_CATALOG([-//OASIS//DTD DocBook XML V4.2//EN],
                            [DocBook XML DTD V4.2], [have_docbookdtd=yes],
                            [have_docbookdtd=no])
       JH_CHECK_XML_CATALOG([http://docbook.sourceforge.net/release/xsl/current/html/refentry.xsl],
                            [DocBook XSL Stylesheets], [have_docbookxsl=yes],
                            [have_docbookxsl=no])
       AS_IF([test "x$have_xsltproc" = "xyes" -a "x$have_docbookdtd" = "xyes" \
              -a "x$have_docbookxsl" = "xyes"],
             [have_manutils=yes],
             [AS_IF([test "x$enable_man_pages" = "xyes"],
                    [AC_MSG_ERROR([man page requested but required utilities were not found])])
              have_manutils=no])],
      [have_manutils=no])

AM_CONDITIONAL([BUILD_MAN_PAGES], [test "x$have_manutils" = "xyes"])

AC_CONFIG_FILES([Makefile
		vapi/Makefile
		src/Makefile
		man/Makefile
		data/Makefile
		data/icons/Makefile
		po/Makefile.in
		])

AC_OUTPUT
