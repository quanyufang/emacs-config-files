(require 'org)
(require 'org-crypt)

(setq org-crypt-key '("C44B4D247957699A"))

(defun sim-log (fmt &rest args)
  (append-to-file (apply #'format fmt args) nil
                  "/Users/fangyu/.emacs.d/.cursor/sim-org-crypt.log"))

(delete-file "/Users/fangyu/.emacs.d/.cursor/sim-org-crypt.log")

(let ((content "* test :crypt:\n\n#+BEGIN_gpg\n-----BEGIN PGP MESSAGE-----\nfakecipher\n-----END PGP MESSAGE-----\n#+END_gpg\n"))
  (with-temp-buffer
    (org-mode)
    (insert content)
    (goto-char (point-min))
    (org-next-visible-heading 1)
    (org-end-of-meta-data 'standard)
    (setq beg (point))
    (goto-char (point-min))
    (org-next-visible-heading 1)
    (org-end-of-subtree t t)
    (setq end (point))
    (sim-log "BOUNDS beg=%d end=%d len=%d\n" beg end (- end beg))
    (sim-log "EXTRACT=%S\n" (buffer-substring-no-properties beg end))
    (sim-log "AT-ENCRYPTED-P=%S\n" (save-excursion
                                     (goto-char (point-min))
                                     (org-next-visible-heading 1)
                                     (org-at-encrypted-entry-p))))
  (with-temp-buffer
    (org-mode)
    (insert content)
    (goto-char (point-min))
    (org-next-visible-heading 1)
    (condition-case err
        (progn
          (org-encrypt-entry)
          (sim-log "AFTER-ENCRYPT size=%d\n" (buffer-size))
          (sim-log "AFTER-ENCRYPT=%S\n" (buffer-string)))
      (error
       (sim-log "ENCRYPT-ERROR=%S\n" (error-message-string err))))))
