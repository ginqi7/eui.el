;;; eui-blueutil.el ---                                  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Qiqi Jin

;; Author: Qiqi Jin  <ginqi7@gmail.com>
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
(require 'eui)

(defcustom eui-blueutil-command (executable-find "blueutil")
  "Specifies the executable path for the blueutil command-line utility used to manage Bluetooth on macOS.")

(defun eui-blueutil-select ()
  (interactive))

(defun eui-blueutil-list-all ()
  "Interactively displays a table in a dedicated buffer listing all paired Bluetooth devices with their name, connection status, and MAC address."
  (interactive)
  (eui-table
   :buffer "*EUI Blue Util*"
   :keys '("name" "connected" "address")
   :hash-table
   (eui-run-sync
    :command (format "%s --paired --format json" eui-blueutil-command))))

(transient-define-prefix eui-blueutil ()
  "Defines a transient menu interface for Bluetooth device management, providing keybindings to select or list devices."
  ["EUI Switchaudio OSX Commands"
   ["Select"
    ("s" "Select Device" eui-blueutil-select)]
   ["List"
    ("l" "List All" eui-blueutil-list-all)]])

(add-to-list 'eui-plugins '("B" "BlueUtil" eui-blueutil))
(eui-transient-setup)

(provide 'eui-blueutil)
;;; blueutil.el ends here
