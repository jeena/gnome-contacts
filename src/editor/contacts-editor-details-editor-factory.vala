/*
 * Copyright (C) 2017 Niels De Graef <nielsdegraef@gmail.com>
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

using Folks;
using Gee;
using Gtk;

/**
 * A Factory for DetailEditors.
 */
public class Contacts.Editor.DetailsEditorFactory : Object {

  /**
   * Creates a DetailEditor for a specific property, given a persona.
   * @return The newly created editor, or null if no editor was created.
   */
  public DetailsEditor? create_details_editor (Persona? p, string prop_name) {
    DetailsEditor? editor = null;

    switch (prop_name) {
      case "birthday":
        var birthday_details = p as BirthdayDetails;
        if (p == null || birthday_details.birthday != null)
          editor = new BirthdayEditor (p as BirthdayDetails);
        break;
      case "email-addresses":
        editor = new EmailsEditor (p as EmailDetails);
        break;
      case "nickname":
        var name_details = p as NameDetails;
        if (p == null || (name_details.nickname != null && name_details.nickname != ""))
          editor = new NicknameEditor (name_details);
        break;
      case "notes":
        editor = new NotesEditor (p as NoteDetails);
        break;
      case "phone-numbers":
        editor = new PhonesEditor (p as PhoneDetails);
        break;
      case "postal-addresses":
        editor = new AddressesEditor (p as PostalAddressDetails);
        break;
      case "urls":
        editor = new UrlsEditor (p as UrlDetails);
        break;
      default:
        debug ("Unsupported property name \"%s\"", prop_name);
        break;
    }

    return editor;
  }
}
