;;; eui.el ---                               -*- lexical-binding: t; -*-

;; Copyright (C) 2025  Qiqi Jin

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
(require 'cl-lib)
(require 'ctable)
(require 'transient)

(defcustom eui-plugins nil
  "List of plugin definitions to be included in the main EUI transient menu.")
;;; Internal Functions
(defun eui-select--join-values (keys hash-table)
  (string-join (mapcar (lambda (key) (format "%s" (gethash key hash-table))) keys) " : "))

(defun eui--json-parser (str)
  "Parse the JSON string STR and return a Lisp object with arrays represented as lists."
  (json-parse-string str :array-type 'list :false-object nil))
;;; Public APIs
(cl-defun eui-run (command callback async))

(cl-defun eui-run-sync (&key command parser callback)
  "Execute COMMAND synchronously, parse the output string with PARSER, and return the result. Defaults to eui--json-parser if PARSER is nil."
  (let ((parser (or parser #'eui--json-parser))
        (json-str (shell-command-to-string command)))
    (funcall parser json-str)))

(defun eui-run-asyc (&key command callback)
  "Execute COMMAND synchronously and return the parsed JSON output as a list. Note that the CALLBACK argument is currently unused."
  (let ((json-str (shell-command-to-string command)))
    (json-parse-string json-str :array 'list)))

(cl-defun eui-table (&key header keys buffer hash-table)
  "Create and display a table in BUFFER using the data from HASH-TABLE. KEYS specifies the columns to display; if nil, keys are extracted from the first entry of HASH-TABLE. The function renders the table using the ctbl library and clears the buffer before drawing."
  (with-current-buffer (get-buffer-create buffer)
    (let* ((keys (or keys (hash-table-keys (car hash-table))))
           (column-model (mapcar (lambda (key) (make-ctbl:cmodel :title (if (stringp key) key (symbol-name key)) :align 'left)) keys))
           (data (mapcar (lambda (one) (mapcar (lambda (key) (gethash key one)) keys)) hash-table))
           (model (make-ctbl:model :column-model column-model :data data))
           (component)
           (inhibit-read-only t))
      (switch-to-buffer (current-buffer))
      (erase-buffer)
      (setq component (ctbl:create-table-component-region :model model))
      (goto-line 3))))

(cl-defun eui-select (&key prompt hash-table keys callback)
  "Prompt the user to select an entry from HASH-TABLE using completion based on values associated with KEYS. Once a selection is made, the corresponding hash table object is passed to CALLBACK."
  (let ((selected (completing-read prompt (mapcar (apply-partially #'eui-select--join-values keys) hash-table))))
    (funcall callback (cl-find-if (lambda (hash) (equal selected (eui-select--join-values keys hash))) hash-table))))

(defun eui-notify (title msg)
  "Display a notification with TITLE and MSG. If the knockknock-notify function is available, it is used to show the notification; otherwise, the message is displayed in the echo area using a formatted string."
  (if (functionp #'knockknock-notify)
      (knockknock-notify
       :title title
       :message msg)
    (message (format "[%s](%s)" title msg))))

(defmacro eui-transient-define-prefix (transient-name transient-body)
  "Define a transient prefix command named TRANSIENT-NAME with the provided TRANSIENT-BODY. This macro acts as a wrapper around transient-define-prefix to initialize a transient interface."
  `(transient-define-prefix ,transient-name ()
     ,transient-body))

(defun eui-transient-setup ()
  "Initialize the main eui transient prefix interface. It dynamically defines the eui command to include a menu of items provided by the eui-plugins list under the section Emacs UI Commands."
  (eval
   `(transient-define-prefix eui ()
      ["Emacs UI Commands"
       ,@eui-plugins])))

(eui-transient-setup)

(provide 'eui)
;;; eui.el ends here
