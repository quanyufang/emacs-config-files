(load "/Users/fangyu/.emacs.d/custom/setup-inline-crypt.el" nil t t)

(defun ic-test-backtrace ()
  (with-current-buffer (generate-new-buffer "*pt2*")
    (insert "-----BEGIN PGP MESSAGE-----\nFAKE\n-----END PGP MESSAGE-----\n")
    (org-mode)
    (message "hook before: %S" before-save-hook)
    (condition-case err
        (inline-crypt--prepare-buffer-for-org-crypt-save)
      (error
       (message "ERROR: %s" (error-message-string err))
       (with-output-to-temp-buffer "*backtrace*"
         (mapc (lambda (f) (princ f) (princ "\n")) (backtrace)))))
    (message "hook after: %S" before-save-hook)))

(ic-test-backtrace)
