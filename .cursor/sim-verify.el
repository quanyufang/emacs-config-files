(require 'org)
(load-file "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el")
(setq org-crypt-key '("C44B4D247957699A"))
(delete-file "/Users/fangyu/.emacs.d/.cursor/sim-verify.log")

(defun sim-log (fmt &rest args)
  (append-to-file (apply #'format fmt args) nil
                  "/Users/fangyu/.emacs.d/.cursor/sim-verify.log"))

(with-temp-buffer
  (org-mode)
  (insert "* h :crypt:\n\n#+BEGIN_gpg\n-----BEGIN PGP MESSAGE-----\nline1\n-----END PGP MESSAGE-----\n#+END_gpg\n")
  (goto-char (point-min))
  (search-forward "-----BEGIN PGP MESSAGE-----")
  (let ((bounds (inline-crypt--find-block-bounds)))
    (sim-log "bounds=%S includes-end-gpg=%S\n" bounds
             (and bounds (string-match-p "#+END_gpg"
                                         (buffer-substring-no-properties (car bounds) (cdr bounds)))))))

(with-temp-buffer
  (org-mode)
  (inline-crypt-mode 1)
  (insert "* 这是秘密 :crypt:\n1234567\n#+END_gpg\n")
  (setq inline-crypt--decrypted-blocks
        (list (list (cons 16 23) "1234567\n"
                    "#+BEGIN_gpg\n-----BEGIN PGP MESSAGE-----\nold\n-----END PGP MESSAGE-----\n#+END_gpg\n")))
  (with-silent-modifications
    (add-text-properties 16 23 '(inline-crypt-decrypted t)))
  (inline-crypt--reencrypt-before-save)
  (sim-log "after-inline size=%d end-gpg-count=%d\n"
           (buffer-size) (how-many "#+END_gpg" (buffer-string)))
  (goto-char (point-min))
  (org-next-visible-heading 1)
  (condition-case err
      (progn (org-encrypt-entry)
             (sim-log "after-org size=%d has-pgp=%S\n"
                      (buffer-size)
                      (string-match-p "-----BEGIN PGP MESSAGE-----" (buffer-string))))
    (error (sim-log "org-error=%S\n" (error-message-string err)))))
