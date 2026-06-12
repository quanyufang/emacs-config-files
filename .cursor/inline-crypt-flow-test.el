(require 'org-crypt)
(load "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el" nil t t)

(with-current-buffer (generate-new-buffer "*flow-test*")
  (org-mode)
  (inline-crypt-mode 1)
  (insert "* sec :crypt:\n")
  (let* ((beg (point))
         (encrypted (inline-crypt--encrypt-plaintext "secret123")))
    (insert "#+BEGIN_gpg\n" encrypted "\n#+END_gpg\n")
    (let ((block (save-excursion
                   (goto-char beg)
                   (forward-line 1)
                   (inline-crypt--find-block-bounds))))
      (when block
        (inline-crypt--collapse-block (car block) (cdr block)))
      (org-encrypt-entries)
      (org-decrypt-entry)
      (goto-char (point-min))
      (search-forward "#+BEGIN_gpg")
      (message "pos=%S collapsed=%S bounds=%S"
               (point)
               (inline-crypt--collapsed-at-point)
               (inline-crypt--find-block-bounds))
      (condition-case err
          (progn
            (inline-crypt-decrypt-at-point)
            (message "decrypted regions=%S plain=%S"
                     (inline-crypt--all-decrypted-regions)
                     (buffer-substring-no-properties
                      (car (car (inline-crypt--all-decrypted-regions)))
                      (cdr (car (car (inline-crypt--all-decrypted-regions))))))
        (error (message "decrypt error: %S" (error-message-string err))))
      (inline-crypt--reencrypt-before-save)
      (message "after reencrypt: begin_gpg=%S pgp=%S"
               (string-match-p "#+BEGIN_gpg" (buffer-string))
               (string-match-p "BEGIN PGP MESSAGE" (buffer-string)))))))
