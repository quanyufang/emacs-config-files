(require 'org)
(load-file "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el")

(with-temp-buffer
  (org-mode)
  (insert "* h :crypt:\n\n#+BEGIN_gpg\n-----BEGIN PGP MESSAGE-----\nline1\n-----END PGP MESSAGE-----\n#+END_gpg\n")
  (goto-char (point-min))
  (search-forward "-----BEGIN PGP MESSAGE-----")
  (let ((bounds (inline-crypt--find-block-bounds))
        (content (buffer-string)))
    (append-to-file
     (format "bounds=%S\nfull=%S\nincludes-end-gpg=%S\n"
             bounds content
             (and bounds (string-match-p "#+END_gpg" (buffer-substring-no-properties (car bounds) (cdr bounds)))))
     nil "/Users/fangyu/.emacs.d/.cursor/sim-bounds.log")))

;; Test extend-end directly
(with-temp-buffer
  (org-mode)
  (insert "-----END PGP MESSAGE-----\n#+END_gpg\n")
  (goto-char (point-min))
  (re-search-forward "-----END PGP MESSAGE-----")
  (let ((end1 (match-end 0))
        (ext (inline-crypt--extend-end-for-closing-delimiter (match-end 0))))
    (append-to-file
     (format "match-end=%d extend=%d end-line=%S\n"
             end1 ext (buffer-substring-no-properties end1 ext))
     nil "/Users/fangyu/.emacs.d/.cursor/sim-bounds.log")))
