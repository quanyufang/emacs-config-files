(load "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el" nil t t)

(delete-file "/Users/fangyu/.emacs.d/.cursor/debug-c9fe51.log" t)

(defun ic-test-append ()
  (let ((log-file "/Users/fangyu/.emacs.d/.cursor/debug-c9fe51.log"))
    (make-directory (file-name-directory log-file) t)
    (with-temp-buffer
      (insert "{\"direct\":true}\n")
      (condition-case err
          (progn
            (append-to-file (point-min) (point-max) log-file)
            (message "append ok"))
        (error (message "append ERR: %s" (error-message-string err)))))))

(ic-test-append)
(inline-crypt--debug-log "via" "fn" "F" '((:x 1)))
(message "file=%S" (with-temp-buffer
                     (when (file-exists-p "/Users/fangyu/.emacs.d/.cursor/debug-c9fe51.log")
                       (insert-file-contents "/Users/fangyu/.emacs.d/.cursor/debug-c9fe51.log")
                       (buffer-string))))
