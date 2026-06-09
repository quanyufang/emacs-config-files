;;; setup-denote.el --- Note management with Denote + Org-roam + Org-crypt

(provide 'setup-denote)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Denote: file-naming based notes     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'denote)

(setq denote-directory (expand-file-name "~/notes/"))
(setq denote-known-keywords '("emacs" "notes" "writing" "reading" "project" "idea"))
(setq denote-infer-keywords t)
(setq denote-sort-keywords t)
(setq denote-file-type nil)          ; nil = support both org and markdown
(setq denote-prompts '(title keywords))
(setq denote-date-format nil)        ; use default ISO 8601
(setq denote-rename-confirmations nil) ; skip confirmation on rename

;; Auto-rename buffers to match denote naming
(denote-rename-buffer-mode 1)

;; Key bindings
(global-set-key (kbd "C-c n d") 'denote-create-note)        ; new note
(global-set-key (kbd "C-c n l") 'denote-link-or-create)     ; link or create
(global-set-key (kbd "C-c n f") 'denote-open-or-create)     ; find or create
(global-set-key (kbd "C-c n r") 'denote-rename-file)        ; rename
(global-set-key (kbd "C-c n k") 'denote-keywords-add)       ; add keywords
(global-set-key (kbd "C-c n b") 'denote-find-backlink)      ; find backlinks
(global-set-key (kbd "C-c n m") 'denote-region)             ; mark region for denote (org)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org-roam: bidirectional links       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'org-roam)

(setq org-roam-directory (file-truename "~/notes/"))
(setq org-roam-db-location (expand-file-name "org-roam.db" org-roam-directory))
(setq org-roam-db-gc-threshold most-positive-fixnum)

;; Capture templates
(setq org-roam-capture-templates
      '(("d" "default" plain "%?"
         :target (file+head "%<%Y%m%dT%H%M%S>-${slug}.org"
                            "#+title: ${title}\n#+date: %<%Y-%m-%d>\n#+filetags: \n\n")
         :unnarrowed t)
        ("b" "bibliography note" plain "%?"
         :target (file+head "%<%Y%m%dT%H%M%S>-${slug}.org"
                            "#+title: ${title}\n#+date: %<%Y-%m-%d>\n#+filetags: :reading:\n\n* Source\n\n* Summary\n\n* Key points\n\n")
         :unnarrowed t)))

;; File exclusion: respect denote naming convention
(setq org-roam-file-exclude-regexp
      '("data/" "archive/" ".git/" ".sync/" "org-roam.db"))

;; Completion: use vertico for node completion
(setq org-roam-node-display-template
      (concat "${title:*} " (propertize "${tags:*}" 'face 'org-tag)))

(org-roam-db-autosync-mode 1)

;; Key bindings (over C-c n prefix)
(global-set-key (kbd "C-c n o") 'org-roam-node-find)       ; find node
(global-set-key (kbd "C-c n i") 'org-roam-node-insert)     ; insert link to node
(global-set-key (kbd "C-c n t") 'org-roam-tag-add)         ; add tag
(global-set-key (kbd "C-c n a") 'org-roam-alias-add)       ; add alias
(global-set-key (kbd "C-c n g") 'org-roam-graph)           ; show graph
(global-set-key (kbd "C-c n s") 'org-roam-db-sync)         ; sync database

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org-crypt: encrypt entries in org   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'org-crypt)

;; Use default GPG key (set to specific key ID if you have multiple)
(setq org-crypt-key nil)

;; Disable auto-save for encrypted entries (security)
(setq org-crypt-disable-auto-save t)

;; Auto-encrypt entries tagged :crypt: before saving
(org-crypt-use-before-save-magic)

;; Tag to trigger encryption
(setq org-crypt-tag-matcher "crypt")

;; Key binding: encrypt/decrypt current entry
(global-set-key (kbd "C-c n c") 'org-encrypt-entry)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org-modern: modern org-mode look    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'org-modern)
(add-hook 'org-mode-hook #'org-modern-mode)
;; Keep a clean look
(setq org-modern-star 'replace)
(setq org-modern-hide-stars nil)
(setq org-modern-table nil)  ; keep standard table formatting for compatibility

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org-mode general enhancements       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Better list behavior
(setq org-list-allow-alphabetical t)

;; Indent org content
(setq org-startup-indented t)

;; Pretty entities (e.g. \alpha → α)
(setq org-pretty-entities t)

;; Show inline images
(setq org-startup-with-inline-images nil) ; off by default, C-c C-x C-v to toggle
(add-hook 'org-mode-hook 'org-display-inline-images)

;; Capture templates (quick capture)
(setq org-capture-templates
      '(("i" "Inbox" entry (file "~/notes/inbox.org")
         "* TODO %?\n  %U\n  %i")
        ("j" "Journal" entry (file+datetree "~/notes/journal.org")
         "* %?\n  %U\n  %i")
        ("n" "Quick note" plain (file denote-directory)
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
;;; │ C-c n c  │ org-encrypt-entry                   │
;;; │ C-c c    │ org-capture                         │
;;; └──────────┴─────────────────────────────────────┘