(load "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el" nil t t)

(with-current-buffer (generate-new-buffer "*pt*")
  (insert "-----BEGIN PGP MESSAGE-----\nFAKE\n-----END PGP MESSAGE-----\n")
  (message "org-mode: %S"
           (condition-case e (progn (org-mode) 'ok) (error (error-message-string e))))
  (message "prepare: %S"
           (condition-case e (inline-crypt--prepare-buffer-for-org-crypt-save)
             (error (error-message-string e))))
  (message "local hook: %S" before-save-hook))
