(load "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el" nil t t)

(let ((log-file (expand-file-name ".cursor/debug-c9fe51.log" user-emacs-directory)))
  (message "log-file=%S dir=%S" log-file user-emacs-directory)
  (condition-case err
      (progn
        (make-directory (file-name-directory log-file) t)
        (with-temp-buffer
          (insert "{\"test\":true}\n")
          (write-region (point-min) (point-max) log-file t 'silent))
        (message "exists=%S size=%S"
                 (file-exists-p log-file)
                 (when (file-exists-p log-file) (file-attribute-size log-file))))
    (error (message "ERR: %s" (error-message-string err)))))

(inline-crypt--debug-log "direct" "call" "F" '((:via "debug-log")))
(message "after debug-log exists=%S"
         (file-exists-p (expand-file-name ".cursor/debug-c9fe51.log" user-emacs-directory)))
