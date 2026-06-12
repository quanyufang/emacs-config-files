(require 'org)
(load-file "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el")

(setq org-crypt-key '("C44B4D247957699A"))

(defun sim-log (fmt &rest args)
  (append-to-file (apply #'format fmt args) nil
                  "/Users/fangyu/.emacs.d/.cursor/sim-org-crypt.log"))

(with-temp-buffer
  (org-mode)
  (inline-crypt-mode 1)
  ;; Simulate post-decrypt state: plaintext + orphan #+END_gpg (bounds bug)
  (insert "* 这是秘密 :crypt:\n")
  (insert "1234567\n")
  (insert "#+END_gpg\n")
  (setq inline-crypt--decrypted-blocks
        (list (list (let ((ov (make-overlay 16 23 nil t nil)))
                     (overlay-put ov 'inline-crypt-decrypted-block t)
                     ov)
                    "1234567\n"
                    "#+BEGIN_gpg\n-----BEGIN PGP MESSAGE-----\nold\n-----END PGP MESSAGE-----\n")))
  (sim-log "BEFORE reencrypt size=%d content=%S\n" (buffer-size) (buffer-string))
  (inline-crypt--reencrypt-before-save)
  (sim-log "AFTER inline reencrypt size=%d pgp=%d content=%S\n"
           (buffer-size)
           (save-excursion (goto-char (point-min)) (let ((n 0)) (while (re-search-forward "-----BEGIN PGP MESSAGE-----" nil t) (setq n (1+ n))) n))
           (buffer-string))
  (goto-char (point-min))
  (org-next-visible-heading 1)
  (condition-case err
      (progn
        (org-encrypt-entry)
        (sim-log "AFTER org-crypt size=%d content=%S\n" (buffer-size) (buffer-string)))
    (error (sim-log "org-crypt ERROR=%S\n" (error-message-string err)))))
