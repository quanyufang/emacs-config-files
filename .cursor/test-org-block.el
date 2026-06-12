(require 'org)
(load-file "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el")

(with-temp-buffer
  (org-mode)
  (insert "* scret :crypt:\n#+BEGIN_gpg\n-----BEGIN PGP MESSAGE-----\nline\n-----END PGP MESSAGE-----\n#+END_gpg\n")
  (message "size=%d has-pgp=%S" (buffer-size)
           (string-match-p "BEGIN PGP MESSAGE" (buffer-string)))
  (goto-char (point-min))
  (message "search=%S" (re-search-forward "BEGIN PGP MESSAGE" nil t))
  (goto-char (point-min))
  (search-forward "-----BEGIN PGP MESSAGE-----")
  (message "bounds=%S" (inline-crypt--find-block-bounds)))
