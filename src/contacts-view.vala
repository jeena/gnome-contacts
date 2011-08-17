/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
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
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

using Gtk;
using Folks;

public class Contacts.View : GLib.Object {
  private class ContactData {
    public Contact contact;
    public TreeIter iter;
    public bool visible;
    public bool is_first;
  }

  Store contacts_store;
  ListStore list_store;
  string []? filter_values;

  public View (Store store) {
    contacts_store = store;

    list_store = new ListStore (2, typeof (Contact), typeof (ContactData *));

    list_store.set_sort_func (0, (model, iter_a, iter_b) => {
	Contact a, b;
	model.get (iter_a, 0, out a);
	model.get (iter_b, 0, out b);
	return a.display_name.collate (b.display_name);
      });
    list_store.set_sort_column_id (0, SortType.ASCENDING);

    contacts_store.added.connect (contact_added_cb);
    contacts_store.removed.connect (contact_removed_cb);
    contacts_store.changed.connect (contact_changed_cb);
    foreach (var c in store.get_contacts ())
      contact_added_cb (store, c);
  }

  public TreeModel model { get { return list_store; } }

  private bool apply_filter (Contact contact) {
    // Don't show the user itself
    if (contact.individual.is_user)
      return false;

    var personas = contact.individual.personas;
    var i = personas.iterator();
    // Look for single-persona individuals
    if (i.next() && !i.has_next ()) {
      var persona = i.get();
      var store = persona.store;

      // Filter out pure key-file persona individuals as these are
      // not very interesting
      if (store.type_id == "key-file")
	return false;

      // Filter out uncertain things like link-local xmpp
      if (store.type_id == "telepathy" &&
	  store.trust_level == PersonaStoreTrust.NONE)
	return false;
    }

    if (filter_values == null || filter_values.length == 0)
      return true;

    return contact.contains_strings (filter_values);
  }

  public bool is_first (TreeIter iter) {
    ContactData *data;
    list_store.get (iter, 1, out data);
    if (data != null)
      return data->is_first;
    return false;
  }

  private ContactData? get_previous (ContactData data) {
    ContactData *previous = null;
    TreeIter iter = data.iter;
    if (list_store.iter_previous (ref iter))
      list_store.get (iter, 1, out previous);
    return previous;
  }

  private ContactData? get_next (ContactData data) {
    ContactData *next = null;
    TreeIter iter = data.iter;
    if (list_store.iter_next (ref iter))
      list_store.get (iter, 1, out next);
    return next;
  }

  private void row_changed_no_resort (ContactData data) {
    var path = list_store.get_path (data.iter);
    list_store.row_changed (path, data.iter);
  }

  private void row_changed_resort (ContactData data) {
    list_store.set (data.iter, 0, data.contact);
  }

  private bool update_is_first (ContactData data, ContactData? previous) {
    bool old_is_first = data.is_first;

    if (previous != null) {
      unichar previous_initial = previous.contact.initial_letter;
      unichar initial = data.contact.initial_letter;
      data.is_first = previous_initial != initial;
    } else {
      data.is_first = true;
    }

    if (old_is_first != data.is_first) {
      row_changed_no_resort (data);
      return true;
    }

    return false;
  }

  private void add_to_model (ContactData data) {
    list_store.append (out data.iter);
    list_store.set (data.iter, 0, data.contact, 1, data);

    if (update_is_first (data, get_previous (data)) && data.is_first) {
      /* The newly added row is first, the next one might not be anymore */
      var next = get_next (data);
      if (next != null)
	update_is_first (next, data);
    }
  }

  private void remove_from_model (ContactData data) {
    ContactData? next = null;
    if (data.is_first)
      next = get_next (data);

    list_store.remove (data.iter);
    data.is_first = false;

    if (next != null)
      update_is_first (next, get_previous (next));
  }

  private void update_visible (ContactData data) {
    bool was_visible = data.visible;
    data.visible = apply_filter (data.contact);

    if (!was_visible && data.visible)
      add_to_model (data);

    if (was_visible && !data.visible)
      remove_from_model (data);
  }

  private void refilter () {
    foreach (var c in contacts_store.get_contacts ()) {
      update_visible (lookup_data (c));
    }
  }

  public void set_filter_values (string []? values) {
    filter_values = values;
    refilter ();
  }

  private void contact_changed_cb (Store store, Contact c) {
    ContactData data = lookup_data (c);

    bool was_visible = data.visible;

    ContactData? next = null;
    if (data.visible)
      next = get_next (data);

    update_visible (data);

    if (was_visible && data.visible) {
      /* We just moved position in the list while visible */

      row_changed_resort (data);

      /* Update the is_first on the previous next row */
      if (next != null)
	update_is_first (next, get_previous (next));

      /* Update the is_first on the new next row */
      next = get_next (data);
      if (next != null)
	update_is_first (next, data);
    }
  }

  private ContactData lookup_data (Contact c) {
    return c.lookup<ContactData> (this);
  }

  private void contact_added_cb (Store store, Contact c) {
    ContactData data =  new ContactData();
    data.contact = c;
    data.visible = false;

    c.set_lookup (this, data);

    update_visible (data);
  }

  private void contact_removed_cb (Store store, Contact c) {
    var data = lookup_data (c);

    if (data.visible)
      remove_from_model (data);

    c.remove_lookup<ContactData> (this);
  }

  public bool lookup_iter (Contact c, out TreeIter iter) {
    var data = lookup_data (c);
    iter = data.iter;
    return data.visible;
  }
}
