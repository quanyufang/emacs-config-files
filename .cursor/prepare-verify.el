(load "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el" nil t t)

(message "=== verify ===")
(with-current-buffer (generate-new-buffer "*verify*")
  (insert "-----BEGIN PGP MESSAGE-----\nX\n-----END PGP MESSAGE-----\n")
  (org-mode)
  (message "prepare: %S"
           (condition-case e (inline-crypt--prepare-buffer-for-org-crypt-save)
             (error (error-message-string e))))
  (message "find side-effect: reencrypt fn=%S"
           (and (fboundp 'inline-crypt--reencrypt-before-save)
                (not (eq (symbol-function 'inline-crypt--reencrypt-before-save)
                         'inline-crypt--prepare-buffer-for-org-crypt-save)))))

(with-current-buffer (generate-new-buffer "*verify2*")
  (insert "#+BEGIN_gpg\n-----BEGIN PGP MESSAGE-----\nline\n-----END PGP MESSAGE-----\n#+END_gpg\n")
  (org-mode)
  (goto-char (point-min))
  (search-forward "-----BEGIN PGP MESSAGE-----")
  (message "inline bounds: %S" (inline-crypt--find-block-bounds))
  (inline-crypt--prepare-buffer-for-org-crypt-save)
  (message "prepare2: ok"))
