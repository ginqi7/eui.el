;;; eui-mole.el ---                                  -*- lexical-binding: t; -*-

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

  ;; mo clean                     Free up disk space
  ;; mo uninstall                 Remove apps completely
  ;; mo optimize                  Refresh caches and services
  ;; mo analyze                   Explore disk usage
  ;; mo status                    Monitor system health
  ;; mo purge                     Remove old project artifacts
  ;; mo installer                 Find and remove installer files
  ;; mo touchid                   Configure Touch ID for sudo
  ;; mo completion                Setup shell tab completion
  ;; mo update                    Update to latest version
;; mo remove                    Remove Mole from system
(require 'eui)
(defcustom eui-mole-command (executable-find "mo")
  "Path to the mo executable command.
Defaults to the location of the mo binary found in the system path.")

(defun eui-mole-clean ()
  "Run the mo clean command asynchronously to clean the project or environment. This function uses the executable path defined in eui-mole-command to execute the clean operation."
  (interactive)
  (eui-run-asyc :command (format "%s clean" eui-mole-command)))

(defun eui-mole-optimize ()
  "Run the mo optimize command asynchronously. This function uses the executable path defined in eui-mole-command to execute the optimization operation."
  (interactive)
  (eui-run-asyc :command (format "%s optimize" eui-mole-command)))

(defun eui-mole-parser (text)
  "Parse the provided text into a list of hash tables. The function identifies the header structure using the first section separated by dashes, then iterates through subsequent lines to extract data. Each resulting hash table represents a row, mapping column headers to their respective values."
  (let* ((header-str (car (split-string text "---")))
         (body-strs (cl-subseq (split-string text "\n" t " +") 2 -1))
         (header (split-string header-str "  " t "[ \n]+")))
    (mapcar (lambda (body)
              (let ((hash (make-hash-table :test #'equal))
                    (items (string-split body "  " t " +")))
                (dolist (idx (number-sequence 0 (1- (length items))))
                  (puthash (nth idx header) (nth idx items) hash))
                hash))
            body-strs)))

(defun eui-mole-uninstall-app (hash)
  "Uninstall the application specified in the provided hash table. The function retrieves the identifier from the UNINSTALL NAME key and executes the uninstall command asynchronously using eui-mole-command while keeping the process buffer."
  (eui-run-asyc :command (format "%s uninstall %s" eui-mole-command (gethash "UNINSTALL NAME" hash))
                :keep-buffer-p t))

(defun eui-mole-select-app ()
  "Interactively select and uninstall an application. The function asynchronously retrieves a list of applications using the mole command, parses the results, and presents a selection interface displaying the name, bundle ID, and size. Once an application is selected, it triggers the uninstallation process."
  (interactive)
  (eui-run-asyc :command (format "%s uninstall --list" eui-mole-command)
                :callbacks (list
                            #'eui-mole-parser
                            (lambda (hash)
                              (eui-select :prompt "Select a app: " :keys '("NAME" "BUNDLE ID" "SIZE") :callback #'eui-mole-uninstall-app :hash-table hash)))))

(defun eui-mole-list-apps ()
  "Interactively list applications in a formatted table. The function asynchronously executes the mole command to list applications, parses the output, and displays the results in a buffer named *Mole*."
  (interactive)
  (eui-run-asyc :command (format "%s uninstall --list" eui-mole-command)
                :callbacks (list
                            #'eui-mole-parser
                            (lambda (hash)
                              (eui-table :buffer "*Mole*" :hash-table hash)))))

(transient-define-prefix eui-mole ()
  "Define a transient prefix command for EUI Mole. This interface provides a structured menu to perform maintenance tasks including cleaning and optimization, as well as application management operations like selecting and listing applications."
  ["EUI Mole Commands"
   ["Run"
    ("c" "Clean" eui-mole-clean)
    ("o" "Optimize" eui-mole-optimize)]
   ["Select"
    ("s" "Select App" eui-mole-select-app)]
   ["List"
    ("l" "List Apps" eui-mole-list-apps)]])

(add-to-list 'eui-plugins '("M" "Mole" eui-mole))
(eui-transient-setup)

(provide 'eui-mole)
;;; eui-mole.el ends here
