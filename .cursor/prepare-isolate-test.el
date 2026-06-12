(load "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el" nil t t)

(message "global hook= %S" (default-value 'before-save-hook))

(with-current-buffer (generate-new-buffer "*dbg*")
  (condition-case err
      (inline-crypt--debug-log "loc" "msg" "F" '((:x 1)))
    (error (message "debug-log ERR: %s" (error-message-string err)))
    (nil (message "debug-log OK"))))

(with-current-buffer (generate-new-buffer "*prep-min*")
  (insert "-----BEGIN PGP MESSAGE-----\nX\n-----END PGP MESSAGE-----\n")
  (setq-local before-save-hook nil)
  (let ((inline-crypt--preparing-p t)
        (iterations 0)
        (before-save-hook nil))
    (condition-case err
        (save-excursion
          (goto-char (point-min))
          (while (re-search-forward (regexp-quote inline-crypt--pgp-begin) nil t)
            (setq iterations (1+ iterations))
            (goto-char (point-max))))
      (error (message "while ERR: %s" (error-message-string err)))
      (nil (message "while OK iterations=%d" iterations)))))

(with-current-buffer (generate-new-buffer "*prep-full*")
  (insert "-----BEGIN PGP MESSAGE-----\nX\n-----END PGP MESSAGE-----\n")
  (setq-local before-save-hook nil)
  (condition-case err
      (inline-crypt--prepare-buffer-for-org-crypt-save)
    (error (message "prepare ERR: %s" (error-message-string err)))
    (nil (message "prepare OK"))))
