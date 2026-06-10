;;; setup-denote.el --- Note management with Denote + Org-roam + Org-crypt

(provide 'setup-denote)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Denote: file-naming based notes     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(when (require 'denote nil t)
  (setq denote-directory (expand-file-name "~/notes/"))
  (setq denote-known-keywords '("emacs" "notes" "writing" "reading" "project" "idea"))
  (setq denote-infer-keywords t)
  (setq denote-sort-keywords t)
  (setq denote-file-type nil)          ; nil = support both org and markdown
  (setq denote-prompts '(title keywords))
  (setq denote-date-format nil)        ; use default ISO 8601
  (setq denote-rename-confirmations nil)

  (denote-rename-buffer-mode 1)

  (global-set-key (kbd "C-c n d") 'denote-create-note)
  (global-set-key (kbd "C-c n l") 'denote-link-or-create)
  (global-set-key (kbd "C-c n f") 'denote-open-or-create)
  (global-set-key (kbd "C-c n r") 'denote-rename-file)
  (global-set-key (kbd "C-c n k") 'denote-keywords-add)
  (global-set-key (kbd "C-c n b") 'denote-find-backlink)
  (global-set-key (kbd "C-c n m") 'denote-region))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org-roam: bidirectional links       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(when (require 'org-roam nil t)
  (setq org-roam-directory (file-truename "~/notes/"))
  (setq org-roam-db-location (expand-file-name "org-roam.db" org-roam-directory))
  (setq org-roam-db-gc-threshold most-positive-fixnum)

  (setq org-roam-capture-templates
        '(("d" "default" plain "%?"
           :target (file+head "%<%Y%m%dT%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %<%Y-%m-%d>\n#+filetags: \n\n")
           :unnarrowed t)
          ("b" "bibliography note" plain "%?"
           :target (file+head "%<%Y%m%dT%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %<%Y-%m-%d>\n#+filetags: :reading:\n\n* Source\n\n* Summary\n\n* Key points\n\n")
           :unnarrowed t)))

  (setq org-roam-file-exclude-regexp
        '("data/" "archive/" ".git/" ".sync/" "org-roam.db"))

  (setq org-roam-node-display-template
        (concat "${title:*} " (propertize "${tags:*}" 'face 'org-tag)))

  (org-roam-db-autosync-mode 1)

  (global-set-key (kbd "C-c n o") 'org-roam-node-find)
  (global-set-key (kbd "C-c n i") 'org-roam-node-insert)
  (global-set-key (kbd "C-c n t") 'org-roam-tag-add)
  (global-set-key (kbd "C-c n a") 'org-roam-alias-add)
  (global-set-key (kbd "C-c n g") 'org-roam-graph)
  (global-set-key (kbd "C-c n s") 'org-roam-db-sync))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org-crypt: encrypt entries in org   ;;
;; (does NOT depend on denote/org-roam) ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'org-crypt)

;; Use Emacs minibuffer for GPG passphrase prompts (fixes "Inappropriate ioctl" on macOS)
(setq epa-pinentry-mode 'loopback)

;; Auto-fold encrypted entries on file open to show just the heading + lock indicator
(defun org-crypt--hide-all-encrypted-entries ()
  "Fold all encrypted entries so they show as single-line headings."
  (org-with-wide-buffer
   (org-map-entries
    (lambda ()
      (when (org-at-encrypted-entry-p)
        (if (fboundp 'org-fold-hide-entry)
            (org-fold-hide-entry)
          (org-hide-entry))))
    "crypt" 'file)))
(add-hook 'org-mode-hook #'org-crypt--hide-all-encrypted-entries)

;; After manual decryption (C-c n c), the entry expands for editing.
;; After save, org-encrypt-entries re-encrypts and folds it back.

;; GPG key is stored in setup-local.el (gitignored, never committed).
;; Run M-x emacs-setup-gpg to configure it interactively.
(defun org-crypt--load-local-key ()
  "Load my-org-crypt-key from setup-local.el if present."
  (let ((local-file (expand-file-name "custom/setup-local.el" user-emacs-directory)))
    (when (file-readable-p local-file)
      (load local-file nil t))
    (when (and (boundp 'my-org-crypt-key) my-org-crypt-key)
      my-org-crypt-key)))

(setq org-crypt-key (or (org-crypt--load-local-key)
                        '("PLACEHOLDER-RUN-M-x-emacs-setup-gpg")))
(setq org-crypt-disable-auto-save t)
(setq org-crypt-tag-matcher "crypt")

;; Auto-encrypt :crypt: entries before every save, with detailed error reporting
(defun org-crypt--validate-key ()
  "Validate that a usable GPG key is configured.  Returns t if OK, nil with warning if not."
  (cond
   ;; Placeholder still present — guide user to setup
   ((and (listp org-crypt-key)
         (string-match-p "PLACEHOLDER\|AAAA1111\|XXXX1234\|placeholder"
                         (car org-crypt-key)))
    (display-warning 'org-crypt
                     (concat
                      "org-crypt-key is still a placeholder.  Edit ~/.emacs.d/custom/setup-denote.el:\n"
                      "  (setq org-crypt-key '(\"YOUR-40-CHAR-FINGERPRINT\"))\n"
                      "Run: gpg --list-keys --keyid-format LONG  to find your fingerprint.")
                     :error)
    nil)
   ;; nil but login name doesn't match any key
   ((null org-crypt-key)
    (require 'epa)
    (unless (epg-list-keys (epg-make-context) (user-login-name))
      (display-warning 'org-crypt
                       (format
                        (concat
                         "No GPG key matches your login name \"%s\".\n"
                         "Set org-crypt-key to your fingerprint in setup-denote.el:\n"
                         "  (setq org-crypt-key '(\"YOUR-FINGERPRINT\"))\n"
                         "Current GPG keys: %s")
                        (user-login-name)
                        (mapconcat (lambda (k)
                                     (epg-sub-key-id (car (epg-key-sub-key-list k))))
                                   (epg-list-keys (epg-make-context)) ", "))
                       :error)
      nil)
    t)
   ;; Explicit key set — check it exists
   (t
    (require 'epa)
    (let ((key-ids (if (listp org-crypt-key) org-crypt-key (list org-crypt-key)))
          (all-keys (epg-list-keys (epg-make-context)))
          found)
      (dolist (kid key-ids)
        (when (seq-find (lambda (k)
                          (string-match-p kid (epg-sub-key-id (car (epg-key-sub-key-list k)))))
                        all-keys)
          (setq found t)))
      (unless found
        (display-warning 'org-crypt
                         (format
                          (concat
                           "Configured org-crypt-key (%s) not found in GPG keyring.\n"
                           "Run: gpg --list-keys --keyid-format LONG\n"
                           "Then update ~/.emacs.d/custom/setup-denote.el")
                          org-crypt-key)
                         :error)
        nil)
      t))))

(add-hook 'org-mode-hook
          (lambda ()
            (add-hook 'before-save-hook
                      (lambda ()
                        (when (and (eq major-mode 'org-mode)
                                   (org-crypt--validate-key))
                          (condition-case err
                              (org-encrypt-entries)
                            (error
                             (display-warning
                              'org-crypt
                              (format "Encryption failed: %s" (error-message-string err))
                              :error)))))
                      nil t)))

;; C-c n c: decrypt entry to view/edit (save re-encrypts automatically)
(global-set-key (kbd "C-c n c") 'org-decrypt-entry)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org-modern: modern org-mode look    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(when (require 'org-modern nil t)
  (add-hook 'org-mode-hook #'org-modern-mode)
  (setq org-modern-star 'replace)
  (setq org-modern-hide-stars nil)
  (setq org-modern-table nil))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org-mode general enhancements       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setq org-list-allow-alphabetical t)
(setq org-startup-indented t)
(setq org-pretty-entities t)
(setq org-startup-with-inline-images nil)
(add-hook 'org-mode-hook 'org-display-inline-images)

;; Quick capture
(setq org-capture-templates
      '(("i" "Inbox" entry (file "~/notes/inbox.org")
         "* TODO %?\n  %U\n  %i")
        ("j" "Journal" entry (file+datetree "~/notes/journal.org")
         "* %?\n  %U\n  %i")
        ("n" "Quick note" plain (file "~/notes/")
         "#+title: %^{Title}\n#+date: %U\n\n%?"
         :no-save t)))

(global-set-key (kbd "C-c c") 'org-capture)

;;; ── Interactive GPG setup (saves to setup-local.el) ─────────
(defun emacs-setup-gpg ()
  "Interactively select a GPG key for org-crypt and save to setup-local.el.
The fingerprint is stored in custom/setup-local.el which is gitignored."
  (interactive)
  (unless (executable-find "gpg")
    (user-error "GPG not found. Install with: brew install gnupg"))
  (require 'epa)
  (let* ((all-keys (epg-list-keys (epg-make-context)))
         (choices
          (mapcar (lambda (k)
                    (let ((sub (car (epg-key-sub-key-list k))))
                      (cons (format "%-40s  %s"
                                    (epg-sub-key-id sub)
                                    (epg-user-id-string (car (epg-key-user-id-list k))))
                            (epg-sub-key-id sub))))
                  all-keys)))
    (if (null choices)
        (user-error "No GPG keys found.  Run: gpg --full-generate-key")
      ;; If only one key, use it directly without prompting
      (let ((fingerprint
             (if (= (length choices) 1)
                 (cdar choices)
               (cdr (assoc
                     (completing-read
                      (format "Select GPG key (%d available): " (length choices))
                      choices nil t)
                     choices))))
             (local-file
              (expand-file-name "custom/setup-local.el" user-emacs-directory)))
        ;; Write the key to setup-local.el
        (with-temp-buffer
          (insert ";; Local GPG key for org-crypt — auto-generated, do not commit.\n")
          (insert (format "(defvar my-org-crypt-key '%S)\n"
                          (list fingerprint)))
          (write-file local-file))
        ;; Reload and apply
        (setq org-crypt-key (list fingerprint))
        (message "GPG key saved to %s (gitignored).  org-crypt is now ready."
                 local-file)))))

;;; Keybinding summary (all under C-c n prefix):
;;; ┌──────────┬─────────────────────────────────────┐
;;; │ Key      │ Function                            │
;;; ├──────────┼─────────────────────────────────────┤
;;; │ C-c n d  │ denote-create-note                  │
;;; │ C-c n l  │ denote-link-or-create               │
;;; │ C-c n f  │ denote-open-or-create               │
;;; │ C-c n r  │ denote-rename-file                  │
;;; │ C-c n k  │ denote-keywords-add                 │
;;; │ C-c n b  │ denote-find-backlink                │
;;; │ C-c n o  │ org-roam-node-find                  │
;;; │ C-c n i  │ org-roam-node-insert                │
;;; │ C-c n t  │ org-roam-tag-add                    │
;;; │ C-c n a  │ org-roam-alias-add                  │
;;; │ C-c n g  │ org-roam-graph                      │
;;; │ C-c n s  │ org-roam-db-sync                    │
;;; │ C-c n c  │ org-decrypt-entry（解密查看加密条目）   │
;;; │ C-c c    │ org-capture                          │
;;; └──────────┴─────────────────────────────────────┘