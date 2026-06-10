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
   '(zygospore w3m volatile-highlights vlf undo-tree smartparens shell-pop recentf-ext rainbow-mode markdown-mode iedit ibuffer-vc highlight-symbol grandshell-theme golden-ratio expand-region duplicate-thing dtrt-indent discover-my-major diff-hl comment-dwim-2 clean-aindent-mode anzu ws-butler yasnippet unicad ztree denote org-roam org-modern vertico consult marginalia orderless embark embark-consult wgrep))
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
    undo-tree
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

;;; Robust package installation with error recovery
(defvar packages-failed '()
  "List of packages that failed to install during startup.")

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
             (message "Package refresh failed, retrying (%d attempts left)... %s"
                      retries (error-message-string err))
           (message "WARNING: Package refresh failed after all retries: %s"
                    (error-message-string err))))))))

(defun install-packages ()
  "Install all required packages with per-package error handling."
  (interactive)
  ;; Refresh archives if needed
  (unless package-archive-contents
    (message "Refreshing package archives, please wait...")
    (package-refresh-with-retry))

  ;; Check which packages need installing
  (let ((to-install
         (seq-filter (lambda (p) (not (package-installed-p p)))
                     packages-need)))
    (if (null to-install)
        (message "All %d required packages are already installed."
                 (length packages-need))
      (message "Installing %d new package(s) of %d total..."
               (length to-install) (length packages-need))

      ;; Install one by one with error handling
      (dolist (package to-install)
        (condition-case err
            (progn
              (message "  Installing %s..." (symbol-name package))
              (package-install package))
          (error
           (message "  ERROR installing %s: %s"
                    (symbol-name package)
                    (error-message-string err))
           (push package packages-failed)))))

    ;; Summary
    (let ((failed-count (length packages-failed)))
      (cond
       ((= failed-count 0)
        (message "Package installation complete (%d installed)."
                 (length to-install)))
       ((< failed-count (length to-install))
        (message "WARNING: %d package(s) failed to install: %s"
                 failed-count
                 (mapconcat #'symbol-name packages-failed ", ")))
       (t
        (message "WARNING: All package installations failed. Check network connection.")
        (message "Failed packages: %s"
                 (mapconcat #'symbol-name packages-failed ", ")))))))

(install-packages)

;;; System dependency checks
(defun check-system-dependencies ()
  "Check for optional external tools and warn if missing."
  (interactive)
  (let ((optional-deps
         '(("rg" . "ripgrep: install with `brew install ripgrep` (used by consult-ripgrep)")
           ("gpg" . "GnuPG: install with `brew install gnupg` (required for org-crypt)")
           ("gpg2" . "GnuPG: install with `brew install gnupg` (required for org-crypt)"))))
    (dolist (dep optional-deps)
      (unless (executable-find (car dep))
        (display-warning 'init
                         (format "Missing optional tool: %s" (cdr dep))
                         :warning)))))

(check-system-dependencies)

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

;;; Startup summary
(add-hook 'after-init-hook
          (lambda ()
            (let ((msg (format "Emacs %d ready — %d packages loaded"
                               emacs-major-version
                               (length packages-need))))
              (when packages-failed
                (setq msg (concat msg
                                  (format " (%d failed: %s)"
                                          (length packages-failed)
                                          (mapconcat #'symbol-name packages-failed ", ")))))
              (message msg))))