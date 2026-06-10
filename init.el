;; -*- lexical-binding: t -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Emacs Configuration - init.el        ;;
;;                                      ;;
;; Focus: Text editing & note management;;
;; Target: Emacs 30+                    ;;
;; Branch: emacs30-upgrade               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Package setup
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu"   . "https://elpa.gnu.org/packages/")))
(setq package-install-upgrade-built-in t)  ; allow upgrading built-in deps like transient
(package-initialize)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-faces-vector
   [default bold shadow italic underline bold bold-italic bold])
 '(ansi-color-names-vector
   (vector "#4d4d4c" "#c82829" "#718c00" "#eab700" "#4271ae" "#8959a8" "#3e999f" "#ffffff"))
 '(beacon-color "#f2777a")
 '(custom-enabled-themes '(grandshell))
 '(custom-safe-themes
   '("3860a842e0bf585df9e5785e06d600a86e8b605e5cc0b74320dfe667bcbe816c" "f9574c9ede3f64d57b3aa9b9cef621d54e2e503f4d75d8613cbcc4ca1c962c21" "b9293d120377ede424a1af1e564ba69aafa85e0e9fd19cf89b4e15f8ee42a8bb" "8d1e447fea4fc82aac533ca87be3f120daffc2905229c01f07ba18ad1edcc376" "82d2cac368ccdec2fcc7573f24c3f79654b78bf133096f9b40c20d97ec1d8016" "1b8d67b43ff1723960eb5e0cba512a2c7a2ad544ddb2533a90101fd1852b426e" "628278136f88aa1a151bb2d6c8a86bf2b7631fbea5f0f76cba2a0079cd910f7d" "f0d8af755039aa25cd0792ace9002ba885fd14ac8e8807388ab00ec84c9497d7" "06f0b439b62164c6f8f84fdda32b62fb50b6d00e8b01c2208e55543a6337433a" "bb08c73af94ee74453c90422485b29e5643b73b05e8de029a6909af6a3fb3f58" default))
 '(exec-path
   '("/usr/bin" "/bin" "/usr/sbin" "/sbin" "/usr/local/bin" "~/bin/global/bin" "~/.emacs.d/manual-install/mew-6.7/bin" "/Library/TeX/Distributions/Programs/texbin" "/Library/TeX/texbin/xelatex"))
 '(fci-rule-color "#d6d6d6")
 '(frame-background-mode 'dark)
 '(line-number-mode t)
 '(package-selected-packages
   '(zygospore w3m volatile-highlights vlf smartparens shell-pop recentf-ext rainbow-mode markdown-mode iedit ibuffer-vc highlight-symbol grandshell-theme golden-ratio expand-region duplicate-thing dtrt-indent discover-my-major diff-hl comment-dwim-2 clean-aindent-mode anzu ws-butler yasnippet unicad ztree denote org-roam org-modern vertico consult marginalia orderless embark embark-consult wgrep))
 '(send-mail-function 'smtpmail-send-it)
 '(smtpmail-smtp-server "smtp.gmail.com")
 '(smtpmail-smtp-service 587)
 '(vc-annotate-background nil)
 '(vc-annotate-color-map
   '((20 . "#c82829")
     (40 . "#f5871f")
     (60 . "#eab700")
     (80 . "#718c00")
     (100 . "#3e999f")
     (120 . "#4271ae")
     (140 . "#8959a8")
     (160 . "#c82829")
     (180 . "#f5871f")
     (200 . "#eab700")
     (220 . "#718c00")
     (240 . "#3e999f")
     (260 . "#4271ae")
     (280 . "#8959a8")
     (300 . "#c82829")
     (320 . "#f5871f")
     (340 . "#eab700")
     (360 . "#718c00")))
 '(vc-annotate-very-old-color nil)
 '(window-divider-mode nil))

;; Use y-or-n-p instead of yes-or-no-p for brevity
(defalias 'yes-or-no-p 'y-or-n-p)

;;; Required packages list (text editing & note taking focused)
(defconst packages-need
  '(anzu
    clean-aindent-mode
    comment-dwim-2
    consult
    denote
    diff-hl
    discover-my-major
    dtrt-indent
    duplicate-thing
    embark
    embark-consult
    expand-region
    golden-ratio
    grandshell-theme
    highlight-symbol
    ibuffer-vc
    iedit
    marginalia
    markdown-mode
    orderless
    org-modern
    org-roam
    rainbow-mode
    recentf-ext
    shell-pop
    smartparens
    unicad
    vertico
    vlf
    volatile-highlights
    w3m
    wgrep
    ws-butler
    yasnippet
    zygospore
    ztree))

;;; ── Fast local check (no network) ───────────────────────────
(defun packages-missing ()
  "Return list of required packages not yet installed, purely from local cache."
  (seq-filter (lambda (p) (not (package-installed-p p)))
              packages-need))

;;; ── Background update checker ──────────────────────────────
(defvar packages-update-checked-p nil
  "Non-nil when the idle update check has already run this session.")

(defun packages--idle-check-for-updates ()
  "Run in idle timer: check for upgradable packages and notify the user."
  (when (and (not packages-update-checked-p)
             package-archive-contents)
    (let ((upgradable
           (seq-filter
            (lambda (p)
              (let ((installed (cadr (assq (car p) package-alist))))
                (and installed (version-list-< (package-desc-version installed)
                                               (package-desc-version (cadr p))))))
            package-archive-contents)))
      (setq packages-update-checked-p t)
      (when upgradable
        (message "📦 %d package(s) have updates available — M-x emacs-update-packages to review"
                 (length upgradable))))))

(run-with-idle-timer 30 nil #'packages--idle-check-for-updates)

;;; ── Startup status report ─────────────────────────────────
(add-hook 'after-init-hook
          (lambda ()
            (let ((missing (packages-missing)))
              (cond
               (missing
                (display-warning
                 'init
                 (format "%d package(s) need to be installed: %s\nM-x emacs-install-packages to install now."
                         (length missing)
                         (mapconcat #'symbol-name missing ", "))
                 :warning))
               (t
                (message "All %d required packages are installed." (length packages-need)))))))

;;; ── Interactive: install missing packages ──────────────────
(defun package-refresh-with-retry (&optional max-retries)
  "Refresh package archives with retry on failure."
  (let ((retries (or max-retries 3))
        (success nil))
    (while (and (> retries 0) (not success))
      (condition-case err
          (progn
            (package-refresh-contents)
            (setq success t))
        (error
         (setq retries (1- retries))
         (if (> retries 0)
             (message "Refresh failed, retrying (%d left)... %s"
                      retries (error-message-string err))
           (error "Package refresh failed: %s"
                  (error-message-string err))))))))

(defun emacs-install-packages ()
  "Install all required packages.  Refresh archives first, show progress.
Call this if you see package warnings at startup."
  (interactive)
  (let ((missing (packages-missing)))
    (if (null missing)
        (message "All %d packages already installed." (length packages-need))
      (message "Refreshing archives...")
      (package-refresh-with-retry)

      (let ((ok 0) (fail nil) (total (length missing)))
        (dolist (p missing)
          (message "  [%d/%d] Installing %s..." (1+ ok) total (symbol-name p))
          (condition-case err
              (progn
                (package-install p)
                (setq ok (1+ ok)))
            (error
             (let ((msg (error-message-string err)))
               (if (string-match-p "Not found" msg)
                   ;; Stale cache: refresh once and retry
                   (progn
                     (message "  Stale cache for %s, refreshing..." (symbol-name p))
                     (package-refresh-contents)
                     (condition-case err2
                         (progn
                           (package-install p)
                           (setq ok (1+ ok)))
                       (error
                        (message "  ✗ %s" (error-message-string err2))
                        (push (cons p msg) fail))))
                 (message "  ✗ %s: %s" (symbol-name p) msg)
                 (push (cons p msg) fail))))))
        (message "Done: %d installed, %d failed (of %d total)."
                 ok (length fail) total)
        (when fail
          (message "Failed: %s"
                   (mapconcat (lambda (f) (format "%s" (car f))) fail ", ")))))))

;;; ── Interactive: check for and apply package updates ───────
(defun emacs-update-packages ()
  "Show a list of packages with available updates and offer to upgrade.
Refreshes archive contents first, then presents a diff-like buffer."
  (interactive)
  (message "Checking for updates...")
  (package-refresh-contents)
  (let ((upgradable
         (seq-filter
          (lambda (p)
            (let ((installed (cadr (assq (car p) package-alist))))
              (and installed
                   (version-list-< (package-desc-version installed)
                                   (package-desc-version (cadr p))))))
          package-archive-contents)))
    (if (null upgradable)
        (message "All packages are up to date.")
      ;; Build a display buffer
      (with-current-buffer (get-buffer-create "*Package Updates*")
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert (format "Updates available for %d package(s):\n\n" (length upgradable)))
          (dolist (p upgradable)
            (let* ((name     (car p))
                   (archive  (cadr p))
                   (installed (cadr (assq name package-alist)))
                   (old-ver  (package-version-join (package-desc-version installed)))
                   (new-ver  (package-version-join (package-desc-version archive))))
              (insert (format "  %-30s %s → %s\n" (symbol-name name) old-ver new-ver))))
          (insert "\nPress 'u' to upgrade all, 'q' to quit.\n"))
        (package-menu-mode)
        (goto-char (point-min))
        (pop-to-buffer (current-buffer))))))

;;; ── Interactive: clean orphaned packages ───────────────────
(defun emacs-clean-orphan-packages ()
  "Remove packages not in `packages-need' that are safe to delete.
Show the list first and ask for confirmation."
  (interactive)
  (let ((orphans
         (seq-filter
          (lambda (pkg-desc)
            (not (memq (package-desc-name pkg-desc) packages-need)))
          (cdr (if (fboundp 'package--alist)
                   (package--alist)
                 package-alist)))))
    (if (null orphans)
        (message "No orphaned packages found — all %d packages are needed."
                 (length packages-need))
      ;; Show what would be removed
      (with-current-buffer (get-buffer-create "*Orphaned Packages*")
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert (format "%d orphaned package(s) not in current config:\n\n" (length orphans)))
          (dolist (p orphans)
            (let* ((name (package-desc-name p))
                   (ver  (package-version-join (package-desc-version p)))
                   (dir  (package-desc-dir p)))
              (insert (format "  %-30s %s\n    %s\n" (symbol-name name) ver dir))))
          (insert "\nPress 'd' to delete all, 'q' to cancel.\n"))
        (let ((map (make-sparse-keymap)))
          (define-key map (kbd "d")
                      (lambda ()
                        (interactive)
                        (dolist (p orphans)
                          (let ((dir (package-desc-dir p)))
                            (when (and dir (file-directory-p dir))
                              (delete-directory dir t)
                              (message "Deleted %s" (package-desc-name p)))))
                        (message "Removed %d orphaned packages. Restart Emacs."
                                 (length orphans))
                        (kill-buffer)))
          (define-key map (kbd "q") (lambda () (interactive) (kill-buffer)))
          (use-local-map map))
        (goto-char (point-min))
        (pop-to-buffer (current-buffer))))))

;;; ── Interactive: recompile stale packages ─────────────────
(defun emacs-recompile-packages ()
  "Byte-recompile all installed packages to eliminate stale .elc warnings."
  (interactive)
  (message "Recompiling packages (this may take a minute)...")
  (package-recompile-all)
  (message "Package recompilation complete."))

;;; ── Fix transient version for magit-section ────────────────
;; magit-section (dep of org-roam) requires transient >= 0.13.
;; Emacs 30 ships an older transient as built-in; we must load the
;; upgraded ELPA version before any package tries to load magit-section.
(defun ensure-transient-upgraded ()
  "Ensure the ELPA version of transient is loaded before magit-section needs it.
magit-section (dep of org-roam) requires transient >= 0.13, but Emacs 30
ships an older built-in transient."
  (when (package-installed-p 'transient)
    (let ((dir (package-desc-dir (cadr (assq 'transient package-alist)))))
      (when (and dir (file-directory-p dir) (string-match-p "elpa" dir))
        ;; Unload the built-in transient if already loaded
        (when (featurep 'transient)
          (unload-feature 'transient t))
        ;; Push ELPA version to front of load-path and load it
        (add-to-list 'load-path dir)
        (require 'transient)
        (message "Loaded transient %s"
                 (package-version-join
                  (package-desc-version
                   (cadr (assq 'transient package-alist)))))))))
(ensure-transient-upgraded)

;;; Load custom modules (with graceful degradation)
(add-to-list 'load-path "~/.emacs.d/custom")

;; Core modules (should always succeed)
(require 'mylib)

;; Conditionally load modules that depend on packages
(defun safe-require (module &optional fallback-msg)
  "Require MODULE, displaying FALLBACK-MSG on error but not crashing."
  (condition-case err
      (require module)
    (error
     (display-warning 'init
                      (format "Failed to load %s: %s"
                              (or fallback-msg (symbol-name module))
                              (error-message-string err))
                      :warning))))

(safe-require 'custom-built-in-functions)
(safe-require 'setup-convenience "Text convenience features")
(safe-require 'setup-files "File management")
(safe-require 'setup-text "Text mode configuration")
(safe-require 'setup-data "Data persistence")
(safe-require 'setup-external "Terminal/shell integration")
(safe-require 'setup-communication "Communication features")
(safe-require 'setup-applications "Eshell configuration")
(safe-require 'setup-environment "Environment settings")
(safe-require 'setup-faces-and-ui "Theme and UI")
(safe-require 'setup-help "Help system")
(safe-require 'setup-vertico "Vertico completion framework")
(safe-require 'setup-denote "Note management system")
(safe-require 'setup-inline-crypt "Inline text encryption")
(safe-require 'setup-editing "Text editing enhancements")

;;; General settings

;; Window navigation
(windmove-default-keybindings)

;; Indentation
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(global-set-key (kbd "RET") 'newline-and-indent)

;; Whitespace mode toggle
(global-set-key (kbd "C-c w") 'whitespace-mode)

;; zygospore: smart delete-other-windows
(global-set-key (kbd "C-x 1") 'zygospore-toggle-delete-other-windows)

;; Toggle frame maximized
(global-set-key (kbd "C-x w f") 'toggle-frame-maximized)

;;; macOS specific
(when (equal system-type 'darwin)
  (defun set-exec-path-from-shell-PATH ()
    "Update Emacs exec-path from shell $PATH."
    (let ((path-from-shell
           (replace-regexp-in-string "[[:space:]\n]*$" ""
                                     (shell-command-to-string "$SHELL -l -c 'echo $PATH'"))))
      (setenv "PATH" path-from-shell)
      (setq exec-path (split-string path-from-shell path-separator))))
  (set-exec-path-from-shell-PATH))

;;; System dependency checks (after PATH is set up)
(defun check-system-dependencies ()
  "Check for optional external tools and warn if missing."
  (interactive)
  (let ((optional-deps
         '(("rg" . "ripgrep: install with `brew install ripgrep` (used by consult-ripgrep)")
           ("gpg" . "GnuPG: install with `brew install gnupg` (required for org-crypt)"))))
    (dolist (dep optional-deps)
      (unless (executable-find (car dep))
        (display-warning 'init
                         (format "Missing optional tool: %s" (cdr dep))
                         :warning)))))

(check-system-dependencies)

;;; Frame title
(setq-default frame-title-format
              '(:eval
                (format "%s%d %s@%s: %s %s"
                        "Emacs@"
                        emacs-major-version
                        (or (file-remote-p default-directory 'user)
                            user-real-login-name)
                        (or (file-remote-p default-directory 'host)
                            system-name)
                        (buffer-name)
                        (cond
                         (buffer-file-truename
                          (concat "(" buffer-file-truename ")"))
                         (dired-directory
                          (concat "{" dired-directory "}"))
                         (t
                          "[no file]")))))

;;; Critical directories
(defun ensure-directory (dir)
  "Create directory DIR if it doesn't exist."
  (unless (file-directory-p dir)
    (make-directory dir t)
    (message "Created directory: %s" dir)))

(ensure-directory "~/notes/")

;;; Server for emacsclient
(condition-case err
    (server-start)
  (error
   (display-warning 'init
                    (format "Could not start Emacs server: %s"
                            (error-message-string err))
                    :warning)))

;;; Language & encoding
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)
(add-to-list 'file-coding-system-alist '("\\.org" utf-8))

;;; Custom faces
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(put 'narrow-to-region 'disabled nil)

;;; Startup completed