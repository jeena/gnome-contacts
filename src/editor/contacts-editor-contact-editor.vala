/*
 * Copyright (C) 2011 Alexander Larsson <alexl@redhat.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;
using Folks;
using Gee;

public errordomain Contacts.Editor.SaveError {
  EMPTY_DATA,
  NO_PRIMARY_ADDRESSBOOK,
}

[GtkTemplate (ui = "/org/gnome/contacts/ui/contacts-contact-editor.ui")]
public class Contacts.Editor.ContactEditor : Grid {

  private const string[] DEFAULT_PROPS_NEW_CONTACT = {
    "email-addresses",
    "phone-numbers",
    "postal-addresses"
  };

  // We have a form with fields for each persona.
  private struct Form {
    Persona? persona; // null iff new contact
    Gee.List<DetailsEditor> editors;
  }

  private Contact? contact;

  private Grid container_grid;

  [GtkChild]
  private ScrolledWindow main_sw;

  [GtkChild]
  private MenuButton add_detail_button;

  [GtkChild]
  public Button linked_button;

  [GtkChild]
  public Button remove_button;

  // The first row of the container_grid that is empty.
  private int next_row = 0;

  private Gee.List<Form?> forms = new LinkedList<Form?> ();

  private DetailsEditorFactory details_editor_factory = new DetailsEditorFactory ();

  public bool has_birthday_row {
    get; private set; default = false;
  }

  public bool has_nickname_row {
    get; private set; default = false;
  }

  public bool has_notes_row {
    get; private set; default = false;
  }

  public ContactEditor (SimpleActionGroup editor_actions) {
    var hcenter = new Center ();
    hcenter.max_width = 600;
    hcenter.xalign = 0.0;

    this.container_grid = new Grid ();
    this.container_grid.row_spacing = 12;
    this.container_grid.column_spacing = 12;
    this.container_grid.vexpand = true;
    this.container_grid.hexpand = true;
    this.container_grid.margin = 36;
    this.container_grid.margin_bottom = 24;

    hcenter.add (this.container_grid);
    this.main_sw.add (hcenter);
    this.container_grid.set_focus_vadjustment (this.main_sw.get_vadjustment ());

    this.main_sw.get_child ().get_style_context ().add_class ("contacts-main-view");
    this.main_sw.get_child ().get_style_context ().add_class ("view");

    this.main_sw.show_all ();

    this.add_detail_button.get_popover ().insert_action_group ("edit", editor_actions);
  }

  /**
   * Adjusts the ContactEditor to the given contact.
   * Use clear() to make sure nothing is lingering from the previous one.
   */
  public void edit (Contact c) {
    this.contact = c;

    this.remove_button.show ();
    this.linked_button.show ();
    this.remove_button.sensitive = this.contact.can_remove_personas ();
    this.linked_button.sensitive = this.contact.individual.personas.size > 1;

    bool first_persona = true;
    foreach (var persona in c.get_personas_for_display ()) {
      add_widgets_for_persona (persona, first_persona);
      first_persona = false;
    }
  }

  /**
   * Adjusts the ContactEditor for a new contact.
   * Use clear() to make sure nothing is lingering from the previous one.
   */
  public void set_new_contact () {
    this.contact = null;

    this.remove_button.hide ();
    this.linked_button.hide ();

    add_widgets_for_persona (null, true);
  }

  /**
   * Adds the widgets for the details in a persona
   */
  private void add_widgets_for_persona (Persona? p, bool first_persona) {
    var form = Form ();
    form.persona = p;
    form.editors = new ArrayList<DetailsEditor> ();
    this.forms.add (form);

    if (first_persona) {
      create_avatar_frame (form);
      create_name_entry (form);
      this.next_row += 3;
    } else {
      // Don't show the name on the default persona
      var store_name = new Label (Contact.format_persona_store_name_for_contact (p));
      store_name.halign = Align.START;
      store_name.xalign = 0.0f;
      store_name.margin_start = 6;
      this.container_grid.attach (store_name, 0, this.next_row, 2);
      this.next_row++;
    }

    string[] writeable_props;
    if (p != null)
      writeable_props = Contact.sort_persona_properties (p.writeable_properties);
    else
      writeable_props = DEFAULT_PROPS_NEW_CONTACT;

    foreach (var prop in writeable_props)
      add_property (form, prop);
  }

  private void add_property (Form form, string prop_name) {
    var editor = this.details_editor_factory.create_details_editor (form.persona, prop_name);
    if (editor != null) {
      form.editors.add (editor);
      var rows_added = editor.attach_to_grid (this.container_grid, this.next_row);
      this.next_row += rows_added;
    }
  }

  public void clear () {
    foreach (var w in container_grid.get_children ()) {
      w.destroy ();
    }
    this.forms.clear ();

    remove_button.set_sensitive (false);
    linked_button.set_sensitive (false);

    /* clean metadata as well */
    has_birthday_row = false;
    has_nickname_row = false;
    has_notes_row = false;

    /* writable_personas.clear (); */
    contact = null;
  }

  // Creates the contact's current avatar, the big frame on top of the Editor
  private void create_avatar_frame (Form form) {
    var avatar_editor = new AvatarEditor (this.contact, form.persona as AvatarDetails);
    avatar_editor.attach_to_grid (this.container_grid, 0);
    form.editors.add (avatar_editor);
  }

  // Creates the big name entry on the top
  private void create_name_entry (Form form) {
    var full_name_editor = new FullNameEditor (this.contact, form.persona as NameDetails);
    full_name_editor.attach_to_grid (this.container_grid, 0);
    form.editors.add (full_name_editor);
  }

  public async Contact save_changes () throws Error {
    if (this.contact == null) {
      var details = new HashTable<string, Value?> (str_hash, str_equal);
      var contacts_store = App.app.contacts_store;

      //XXX check if name is filled in
      var form = this.forms[0];
      foreach (var details_editor in form.editors)
        if (details_editor.dirty)
          details[details_editor.persona_property] = details_editor.create_value ();

      if (details.size () != 0)
        throw new SaveError.EMPTY_DATA (_("You need to enter some data"));

      if (contacts_store.aggregator.primary_store == null)
        throw new SaveError.NO_PRIMARY_ADDRESSBOOK (_("No primary addressbook configured"));

      // Create the contact
      var primary_store = contacts_store.aggregator.primary_store;
      var persona = yield Contact.create_primary_persona_for_details (primary_store, details);

      return contacts_store.find_contact_with_persona (persona);
    }

    //XXX check for empty values
    foreach (var form in this.forms) {
      foreach (var details_editor in form.editors) {
        if (details_editor.dirty)
          yield details_editor.save_to_persona (form.persona);
      }
    }
    return this.contact;
  }
}
