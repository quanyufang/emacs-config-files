(require 'org)
(load-file "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el")

(with-temp-buffer
  (org-mode)
  (insert-file-contents "/Users/fangyu/note.org")
  (message "disk-only org-pgp size=%d" (buffer-size)))

(with-temp-buffer
  (org-mode)
  (let ((body nil)
        (decrypted "-----BEGIN PGP MESSAGE-----\n\nhF4DCILbpZHLEfASAQdASGJE8kg8Na0/ORgVyD1MljzZS9ZK1pkuowSCLJbuOi0w\nTXDB5VNKh29Xlz4MM+byXjO67+iauCc1VAkyDteqn0DC/FER2AwBHX0qcdV/3uKO\n1E0BCQIQYlR5lrlp2TI1+biNn/MDeEjAkH5Kb/nbEYIHhnfbRy4U/5hz/4zXUme8\nx/h9D0vbqz/dCBB+jMFRajRl/2rMbIySBlOxvYgx+g==\n=p9Ej\n-----END PGP MESSAGE-----\n"))
    (insert "* scret :crypt:\n#+BEGIN_gpg\n" decrypted "#+END_gpg\n\n* not secret\n"))
  (goto-char (search-forward "-----BEGIN PGP MESSAGE-----"))
  (let* ((b (inline-crypt--find-block-bounds))
         (armor (buffer-substring-no-properties (car b) (cdr b)))
         (pgp (inline-crypt--extract-pgp-armor armor)))
    (message "bounds=%S armor-len=%d has-not-secret=%S"
             b (length armor) (string-match-p "not secret" armor))
    (condition-case err
        (let ((plain (decode-coding-string
                      (epg-decrypt-string (epg-make-context 'OpenPGP) pgp)
                      'utf-8)))
          (message "OK plain-len=%d plain=%S" (length plain) plain))
      (error (message "ERR %S" (error-message-string err))))))

(with-temp-buffer
  (org-mode) (inline-crypt-mode 1)
  (insert "* scret :crypt:\n#+BEGIN_gpg\n-----BEGIN PGP MESSAGE-----\n\nhF4DCILbpZHLEfASAQdASGJE8kg8Na0/ORgVyD1MljzZS9ZK1pkuowSCLJbuOi0w\nTXDB5VNKh29Xlz4MM+byXjO67+iauCc1VAkyDteqn0DC/FER2AwBHX0qcdV/3uKO\n1E0BCQIQYlR5lrlp2TI1+biNn/MDeEjAkH5Kb/nbEYIHhnfbRy4U/5hz/4zXUme8\nx/h9D0vbqz/dCBB+jMFRajRl/2rMbIySBlOxvYgx+g==\n=p9Ej\n-----END PGP MESSAGE-----\n\n#+END_gpg\n\n* not secret\n")
  (goto-char (search-forward "-----BEGIN PGP MESSAGE-----"))
  (inline-crypt-decrypt-at-point)
  (message "after-decrypt=%S" (buffer-substring-no-properties (point-min) (point-max))))
