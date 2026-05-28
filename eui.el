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

(defcustom eui-yq-command (executable-find "yq")
  "Specifies the executable path for the yq command-line utility used for processing YAML and other structured data formats.")

(defcustom eui-jq-command (executable-find "jq")
  "Specifies the executable path for the jq command-line utility used for processing and querying JSON data.")

;;; Internal Functions
(defun eui-select--join-values (keys hash-table)
  (string-join (mapcar (lambda (key) (format "%s" (gethash key hash-table))) keys) " : "))

(defun eui--json-parser (str)
  "Parse the JSON string STR and return a Lisp object with arrays represented as lists."
  (json-parse-string str :array-type 'list :false-object nil))

(defun eui--process-sentinel (process event)
  "Sentinel function that handles the termination of a process and executes associated callbacks.

If the EVENT indicates the process has finished successfully, the function switches to the process buffer and retrieves its content. It then sequentially applies each function in the CALLBACKS list to the output, passing the result of each callback as the input to the next. If KEEP-BUFFER-P was not specified as non-nil, the process buffer and its associated window are killed upon completion."
  (let* ((plist (process-plist process))
         (callbacks (plist-get plist 'callbacks))
         (keep-buffer-p (plist-get plist 'keep-buffer-p)))
    (when (string= event "finished\n")
      (with-current-buffer (process-buffer process)
        (when callbacks
          (setq arg (buffer-substring-no-properties (point-min) (point-max)))
          (dolist (callback callbacks)
            (setq arg (funcall callback arg))))
        (unless keep-buffer-p (kill-buffer-and-window))))))

;;; Public APIs
(cl-defun eui-run (command callback async))

(cl-defun eui-run-sync (&key command parser callback)
  "Execute COMMAND synchronously, parse the output string with PARSER, and return the result. Defaults to eui--json-parser if PARSER is nil."
  (let ((parser (or parser #'eui--json-parser))
        (json-str (shell-command-to-string command)))
    (funcall parser json-str)))

(cl-defun eui-run-asyc (&key command callbacks keep-buffer-p)
  "Run COMMAND asynchronously and manage its execution through CALLBACKS.

COMMAND is a string specifying the shell command to run.
CALLBACKS is a list of functions or data to be handled by the sentinel when the process state changes.
KEEP-BUFFER-P is a flag that, when non-nil, prevents the output buffer from being automatically removed.

This function creates dedicated output and error buffers, initiates the asynchronous process, and stores the configuration parameters in the process property list for the sentinel eui--process-sentinel to access."
  (let ((buff-name (format "*eui-%s*" (md5 command)))
        (buff-err-name (format "*eui-err-%s*" (md5 command)))
        (proc))
    (async-shell-command command buff-name buff-err-name)
    (setq proc (get-buffer-process buff-name))
    (set-process-plist proc
                       (list
                        'keep-buffer-p keep-buffer-p
                        'callbacks callbacks))
    (set-process-sentinel proc #'eui--process-sentinel)))

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
