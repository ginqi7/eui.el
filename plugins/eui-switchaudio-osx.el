;;; eui-switchaudio-osx.el ---                       -*- lexical-binding: t; -*-

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

(defcustom eui-switchaudio-osx-command (executable-find "SwitchAudioSource")
  "Specifies the custom variable for the path to the SwitchAudioSource executable used by the switchaudio-osx package. It uses executable-find to locate the command in the system PATH.")

(defvar eui-switchaudio-osx-list-template "sh -c '%s -a -f json; %s -c -f json; %s -c -f json -t input'"
  "A shell command template string used to retrieve a comprehensive list of macOS audio devices, including the current output and input status, formatted as JSON.")

(defvar eui-switchaudio-osx-list-jq-template "jq -s '.[-2:] as $curr | .[0:-2] | map(. as $item | .active = (any($curr[]; .uid == $item.uid and .type == $item.type)))'"
  "A jq command template string used to process JSON-formatted audio device data, marking devices as active if their unique identifiers and types match the currently selected input or output devices.")

(defun eui-switchaudio-osx-list-command ()
  "Generates the complete shell command string for listing macOS audio devices by formatting the underlying switchaudio-osx commands and piping the output into a jq template for processing."
  (format "%s | %s"
          (format eui-switchaudio-osx-list-template
                  eui-switchaudio-osx-command eui-switchaudio-osx-command eui-switchaudio-osx-command)
          eui-switchaudio-osx-list-jq-template))

(defun eui-switchaudio-osx-list-devices ()
  "Displays a list of macOS audio devices in an EUI table buffer by synchronously executing the configured system command."
  (interactive)
  (eui-table
   :buffer "*EUI Switchaudio OSX*"
   :hash-table
   (eui-run-sync
    :command (eui-switchaudio-osx-list-command))))

(defun eui-switchaudio-osx-switch-device (hash)
  "Switches the macOS audio device to the one specified in the input hash table and displays a notification upon completion."
  (eui-run-sync :command (format "%s -s \"%s\"" eui-switchaudio-osx-command (gethash "name" hash))
                :parser (apply-partially #'eui-notify "EUI-Switchaudio-OSX")))

(defun eui-switchaudio-osx-select-device ()
  "Interactively prompts the user to select a macOS audio device from a list and switches the system audio to the selected device."
  (interactive)
  (eui-select
   :prompt "Select a Audio Device: "
   :hash-table
   (eui-run-sync
    :command (eui-switchaudio-osx-list-command))
   :keys '("name" "type" "active")
   :callback #'eui-switchaudio-osx-switch-device))

(transient-define-prefix eui-switchaudio-osx ()
  "Defines a transient menu interface for macOS audio device management, providing keybindings to select or list devices."
  ["EUI Switchaudio OSX Commands"
   ["Select"
    ("s" "Select Device" eui-switchaudio-osx-select-device)]
   ["List"
    ("l" "List Devices" eui-switchaudio-osx-list-devices)]])

(add-to-list 'eui-plugins '("s" "Switchaudio OSX" eui-switchaudio-osx))
(eui-transient-setup)

(provide 'eui-switchaudio-osx)
;;; eui-switchaudio-osx.el ends here
