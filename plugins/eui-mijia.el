;;; eui-mijia.el ---                                 -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Qiqi Jin

;; Author: Qiqi Jin <ginqi7@gmail.com>
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(defcustom eui-mijia-command "uvx mijiaAPI"
  "Customizable variable that specifies the shell command used to invoke the Mijia API.")

(defun eui-mijia-command (type)
  "Generates a shell command string to retrieve and format Mijia device information. It takes a command flag as the type argument, applies a sed transformation to prefix list items with a name key to ensure YAML compatibility, and pipes the output to yq for conversion into JSON format."
  (format "%s %s | sed 's/^  - \\(.*\\)/  - name: \\1/' | yq -o=json" eui-mijia-command type))

(defun eui-mijia-parser (str)
  "Parses a JSON string into a hash table and extracts the value associated with its first top-level key. This is typically used to unwrap the device list array from the root object produced by the formatted command output."
  (let* ((hash (eui--json-parser str))
         (key (car (hash-table-keys hash))))
    (gethash key hash)))

(defun eui-mijia-run-scene (hash)
  "Executes a Mijia scene synchronously using the name retrieved from the provided hash table. It constructs the execution command and sends the output to a system notification with the EUI-MiJia prefix."
  (eui-run-sync :command (format "%s --run_scene %s" eui-mijia-command (gethash "name" hash))
                :parser (apply-partially #'eui-notify "EUI-MiJia")))

(defun eui-mijia-select-scenes ()
  "Prompts the user to select a Mijia scene from a dynamically generated list. It fetches the available scenes synchronously, displays their names for selection, and triggers the execution of the chosen scene upon confirmation."
  (interactive)
  (eui-select
   :prompt "Select a scene: "
   :hash-table
   (eui-run-sync
    :command (eui-mijia-command "--list_scenes")
    :parser #'eui-mijia-parser)
   :keys '("name")
   :callback #'eui-mijia-run-scene))

(defun eui-mijia-list (buffer-name command-template)
  "Displays a list of Mijia items in a tabular format within a specified buffer. It retrieves data by executing a command based on the provided template, parses the results, and populates the table with the retrieved information."
  (eui-table
   :buffer buffer-name
   :hash-table
   (eui-run-sync
    :command (eui-mijia-command command-template)
    :parser #'eui-mijia-parser)))

(defun eui-mijia-list-devices ()
  "Interactively displays a list of Mijia devices in a dedicated buffer named *MiJia Devices*. It fetches the device information by executing the appropriate list command and presents it in a tabular format."
  (interactive)
  (eui-mijia-list "*MiJia Devices*" "--list_devices"))

(defun eui-mijia-list-scenes ()
  "Interactively displays a list of Mijia scenes in a dedicated buffer named *MiJia Devices*. It fetches the scene information by executing the appropriate list command and presents it in a tabular format."
  (interactive)
  (eui-mijia-list "*MiJia Devices*" "--list_scenes"))

(defun eui-mijia-list-consumable-items ()
  "Interactively displays a list of Mijia consumable items in a dedicated buffer named *MiJia Devices*. It fetches the consumable information by executing the appropriate list command and presents it in a tabular format."
  (interactive)
  (eui-mijia-list "*MiJia Devices*" "--list_consumable_items"))

(transient-define-prefix eui-mijia ()
  "Defines a transient prefix command that provides a menu for Mijia-related operations, including selecting scenes and listing devices, scenes, or consumable items."
  ["EUI Mijia Commands"
   ["Select"
    ("ss" "Select Scenes" eui-mijia-select-scenes)]
   ["List"
    ("ld" "List Devices" eui-mijia-list-devices)
    ("ls" "List Scenes" eui-mijia-list-scenes)
    ("lc" "List Consumable Items" eui-mijia-list-consumable-items)]])

(add-to-list 'eui-plugins '("m" "Mijia" eui-mijia))
(eui-transient-setup)

(provide 'eui-mijia)
;;; eui-mijia.el ends here
