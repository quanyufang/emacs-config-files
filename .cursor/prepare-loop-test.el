(load "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el" nil t t)
(delete-file "/Users/fangyu/.emacs.d/.cursor/debug-c9fe51.log")

(with-current-buffer (generate-new-buffer "*prepare-test*")
  (org-mode)
  (insert "-----BEGIN PGP MESSAGE-----\nFAKE\n-----END PGP MESSAGE-----\n")
  (inline-crypt--prepare-buffer-for-org-crypt-save)
  (message "prepare-test OK"))
