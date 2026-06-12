(load "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el" nil t t)

(delete-file "/Users/fangyu/.emacs.d/.cursor/debug-c9fe51.log" t)

(defun e2e-log (fmt &rest args)
  (append-to-file (apply #'format fmt args) nil
                  "/Users/fangyu/.emacs.d/.cursor/e2e-result.log"))

(e2e-log "=== e2e start ===\n")

(with-current-buffer (generate-new-buffer "*e2e*")
  (org-mode)
  (inline-crypt-mode 1)
  (insert "* test :crypt:\n\n#+BEGIN_gpg\n-----BEGIN PGP MESSAGE-----\n")
  (insert "hQIMAxExampleBase64Line1\nhQIMAxExampleBase64Line2\n")
  (insert "-----END PGP MESSAGE-----\n#+END_gpg\n")
  (goto-char (point-min))
  (search-forward "-----BEGIN PGP MESSAGE-----")
  (let ((bounds (inline-crypt--find-block-bounds)))
    (e2e-log "find-block-bounds=%S includes-end-gpg=%S\n"
             bounds
             (and bounds (string-match-p "#+END_gpg"
                                         (buffer-substring-no-properties (car bounds) (cdr bounds))))))
  ;; Simulate decrypted plaintext region (skip gpg - use fake plaintext)
  (goto-char (point-min))
  (search-forward "#+BEGIN_gpg")
  (let ((beg (point))
        (end (save-excursion (search-forward "#+END_gpg" nil t) (line-end-position))))
    (delete-region beg end)
    (insert "my secret plaintext\n")
    (let ((pbeg beg)
          (pend (point)))
      (inline-crypt--register-decrypted pbeg pend "my secret plaintext\n"
                                        "#+BEGIN_gpg\n-----BEGIN PGP MESSAGE-----\nFAKE\n-----END PGP MESSAGE-----\n#+END_gpg\n")
      (with-silent-modifications
        (add-text-properties pbeg pend '(inline-crypt-decrypted t)))
      (setq-local before-save-hook '(inline-crypt--reencrypt-before-save))
      (setq buffer-file-name "/tmp/e2e-note.org")
      (set-buffer-modified-p t)
      (condition-case err
          (progn
            (basic-save-buffer)
            (e2e-log "save: ok size=%s\n"
                     (number-to-string (nth 5 (file-attributes "/tmp/e2e-note.org")))))
        (error (e2e-log "save ERR: %s\n" (error-message-string err))))
      (e2e-log "pgp-after-save=%s\n"
               (number-to-string (save-excursion (goto-char (point-min))
                                   (let ((n 0))
                                     (while (re-search-forward "-----BEGIN PGP MESSAGE-----" nil t)
                                       (setq n (1+ n)))
                                     n)))))))

(e2e-log "=== e2e done ===\n")
