(load "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el" nil t t)

(defun ic-run (label setup-fn)
  (message "=== %s ===" label)
  (with-current-buffer (generate-new-buffer (format "*%s*" label))
    (insert "-----BEGIN PGP MESSAGE-----\nFAKE\n-----END PGP MESSAGE-----\n")
    (funcall setup-fn)
    (message "hook= %S" before-save-hook)
    (condition-case err
        (inline-crypt--prepare-buffer-for-org-crypt-save)
      (error (message "FAIL %s: %s" label (error-message-string err)))
      (nil (message "OK %s" label)))))

(ic-run "plain" #'ignore)
(ic-run "org" (lambda () (org-mode)))
(ic-run "org+ic" (lambda () (org-mode) (inline-crypt-mode 1)))
(ic-run "org-hook-nil" (lambda () (org-mode) (setq-local before-save-hook nil)))
