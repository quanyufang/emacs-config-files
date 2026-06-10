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

;; nil would search by user-login-name which may not match the GPG UID
;; the GPG key UID ("Eric Fang").  Explicitly use the key fingerprint.
;; Replace with your 40-char GPG fingerprint (see gpg --list-keys --keyid-format LONG)
(setq org-crypt-key '("AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555"))
(setq org-crypt-disable-auto-save t)
(setq org-crypt-tag-matcher "crypt")

;; Auto-encrypt :crypt: entries before every save, with error reporting
(add-hook 'org-mode-hook
          (lambda ()
            (add-hook 'before-save-hook
                      (lambda ()
                        (condition-case err
                            (org-encrypt-entries)
                          (error
                           (display-warning
                            'org-crypt
                            (format "Encryption failed: %s\nHint: check org-crypt-key in setup-denote.el"
                                    (error-message-string err))
                            :error))))
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