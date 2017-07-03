NULL =

AM_CPPFLAGS = \
	-include config.h \
	$(CONTACTS_CFLAGS) \
	-DLOCALEDIR=\""$(localedir)"\" \
	-DPKGDATADIR=\""$(pkgdatadir)"\" \
	-DPKGLIBDIR=\""$(pkglibdir)"\" \
	-DGNOME_DESKTOP_USE_UNSTABLE_API \
	$(NULL)

AM_VALAFLAGS = \
	--vapidir=../vapi --pkg config --pkg custom --debug \
	@CONTACTS_PACKAGES@ \
	--target-glib=$(GLIB_REQUIRED) --gresources=$(top_srcdir)/data/contacts.gresource.xml \
	$(NULL)

if BUILD_CHEESE
AM_VALAFLAGS += -D HAVE_CHEESE
AM_CPPFLAGS += $(CHEESE_CFLAGS)
endif

bin_PROGRAMS = gnome-contacts

vala_sources = \
	editor/contacts-editor-addresses-editor.vala \
	editor/contacts-editor-avatar-editor.vala \
	editor/contacts-editor-birthday-editor.vala \
	editor/contacts-editor-composite-editor.vala \
	editor/contacts-editor-contact-editor.vala \
	editor/contacts-editor-details-editor-factory.vala \
	editor/contacts-editor-details-editor.vala \
	editor/contacts-editor-emails-editor.vala \
	editor/contacts-editor-full-name-editor.vala \
	editor/contacts-editor-nickname-editor.vala \
	editor/contacts-editor-notes-editor.vala \
	editor/contacts-editor-phones-editor.vala \
	editor/contacts-editor-urls-editor.vala \
	\
	contacts-app.vala \
	contacts-address-map.vala \
	contacts-contact.vala \
	contacts-contact-sheet.vala \
	contacts-contact-pane.vala \
	contacts-types.vala \
	contacts-in-app-notification.vala \
	contacts-list-pane.vala \
	contacts-linked-accounts-dialog.vala \
	contacts-linking.vala \
	contacts-store.vala \
	contacts-view.vala \
	contacts-utils.vala \
	contacts-avatar-dialog.vala \
	contacts-accounts-list.vala \
	contacts-contact-frame.vala \
	contacts-window.vala \
	main.vala \
	contact-resources.c \
	$(NULL)

gsettings_ENUM_NAMESPACE = org.gnome.Contacts
gsettings_ENUM_FILES = \
        contacts-view.c

gsettings_SCHEMAS = org.gnome.Contacts.gschema.xml

@GSETTINGS_RULES@

resource_files = $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir=$(top_srcdir)/data $(top_srcdir)/data/contacts.gresource.xml)
contact-resources.c: $(top_srcdir)/data/contacts.gresource.xml $(resource_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) --target=$@ --sourcedir=$(top_srcdir)/data --generate-source $<

gnome_contacts_SOURCES = \
	$(vala_sources) \
	cc-crop-area.c \
	contacts-esd-setup.c \
	$(NULL)

gnome_contacts_LDADD = $(CONTACTS_LIBS) -lm

if BUILD_CHEESE
gnome_contacts_LDADD += $(CHEESE_LIBS)
gnome_contacts_SOURCES += \
	cheese-flash.c \
	$(NULL)
endif

libexec_PROGRAMS = gnome-contacts-search-provider

gnome_contacts_search_provider_SOURCES = \
	contacts-contact.vala \
	contacts-esd-setup.c \
	contacts-shell-search-provider.vala \
	contacts-store.vala \
	contacts-types.vala \
	contacts-utils.vala \
	$(NULL)

gnome_contacts_search_provider_LDADD = $(CONTACTS_LIBS)

CLEANFILES = \
	$(vala_sources:.vala=.c) \
	*.vapi *.stamp

EXTRA_DIST = \
	org.gnome.Contacts.gschema.xml \
	cheese-flash.h \
	cc-crop-area.h \
	contacts-esd-setup.h \
	$(NULL)

-include $(top_srcdir)/git.mk
