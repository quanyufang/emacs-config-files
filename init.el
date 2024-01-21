(require 'package)
(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")))
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(setq gc-cons-threshold 800000)
(setq inhibit-startup-message t)
(setenv "PATH" (concat (getenv "PATH") ":/usr/local/texlive/2013/bin/x86_64-darwin/"))
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
 '(column-enforce-column 240 t)
 '(custom-enabled-themes '(grandshell))
 '(custom-safe-themes
   '("3860a842e0bf585df9e5785e06d600a86e8b605e5cc0b74320dfe667bcbe816c" "f9574c9ede3f64d57b3aa9b9cef621d54e2e503f4d75d8613cbcc4ca1c962c21" "b9293d120377ede424a1af1e564ba69aafa85e0e9fd19cf89b4e15f8ee42a8bb" "8d1e447fea4fc82aac533ca87be3f120daffc2905229c01f07ba18ad1edcc376" "82d2cac368ccdec2fcc7573f24c3f79654b78bf133096f9b40c20d97ec1d8016" "1b8d67b43ff1723960eb5e0cba512a2c7a2ad544ddb2533a90101fd1852b426e" "628278136f88aa1a151bb2d6c8a86bf2b7631fbea5f0f76cba2a0079cd910f7d" "f0d8af755039aa25cd0792ace9002ba885fd14ac8e8807388ab00ec84c9497d7" "06f0b439b62164c6f8f84fdda32b62fb50b6d00e8b01c2208e55543a6337433a" "bb08c73af94ee74453c90422485b29e5643b73b05e8de029a6909af6a3fb3f58" default))
 '(ecb-options-version "2.50")
 '(exec-path
   '("/usr/bin" "/bin" "/usr/sbin" "/sbin" "/usr/local/bin" "~/bin/global/bin" "~/.emacs.d/manual-install/mew-6.7/bin" "/Library/TeX/Distributions/Programs/texbin" "/Library/TeX/texbin/xelatex"))
 '(fci-rule-color "#d6d6d6")
 '(flycheck-color-mode-line-face-to-color 'mode-line-buffer-id)
 '(frame-background-mode 'dark)
 '(helm-tramp-verbose 10)
 '(line-number-mode t)
 '(package-selected-packages
   '(py-isort py-yapf undo-tree zygospore ztree ws-butler workgroups2 w3m volatile-highlights vlf smartparens slime-company shell-pop recentf-ext nyan-mode jedi iedit ibuffer-vc highlight-symbol highlight-numbers helm-swoop helm-gtags grandshell-theme golden-ratio ggtags function-args flycheck-tip expand-region ecb duplicate-thing dtrt-indent discover-my-major diff-hl company-jedi company-emacs-eclim company-c-headers comment-dwim-2 column-enforce-mode color-theme-sanityinc-tomorrow clean-aindent-mode anzu))
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
(defalias 'yes-or-no-p 'y-or-n-p)

(defconst packages-need
  '(anzu
    company
    duplicate-thing
    ggtags
    helm
    helm-gtags
    helm-swoop
    function-args
    clean-aindent-mode
    comment-dwim-2
    dtrt-indent
    ws-butler
    iedit
    yasnippet
    smartparens
    volatile-highlights
    undo-tree
    zygospore
    workgroups2
    expand-region
    ibuffer-vc
    ;;dired+
    recentf-ext
    ztree
    vlf
    shell-pop
    diff-hl
    ;;magit
    flycheck
    flycheck-tip
    nyan-mode
    golden-ratio
    highlight-numbers
    discover-my-major
    rainbow-mode
    ;;help+
    ;;help-fns+
    ;;help-mode+
    ;;c/c++
    ecb
    ;;commonq lisp
    slime
    slime-company
    jedi
    highlight-symbol
    color-theme-sanityinc-tomorrow
    grandshell-theme
    ;;info+
    company-c-headers
    ;;psvn
    ;; php
    php-mode
    ;;php-auto-yasnippets
    ;; python
    company-jedi
    markdown-mode
    ;;markdown-mode+
    ;; mew
    w3m
    ;;java
    eclim
    company-emacs-eclim
    ;;ac-emacs-eclim
    column-enforce-mode
    ;;pyim
    ;;pyim
    ;;pyim-basedict
    ;;docker
    ))

(defun install-packages ()
  "Install all required packages."
  (interactive)
  (unless package-archive-contents
    (package-refresh-contents))
  (dolist (package packages-need)
    (unless (package-installed-p package)
      (package-install package))))

(install-packages)



(add-to-list 'load-path "~/.emacs.d/custom")
(add-to-list 'load-path "~/.emacs.d/manual-install/unicad")
(add-to-list 'load-path "~/.emacs.d/manual-install/mew-6.7")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PACKAGE: workgroups2               ;;
;;                                    ;;
;; GROUP: Convenience -> Workgroups   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'workgroups2)
;; Change some settings
(workgroups-mode 1)


;; this variables must be set before load helm-gtags
;; you can change to any prefix key of your choice
(setq helm-gtags-prefix-key "\C-cg")



(require 'custom-built-in-functions)
(require 'mylib)
(require 'setup-convenience)
(require 'setup-files)
(require 'setup-text)
(require 'setup-data)
(require 'setup-external)
(require 'setup-communication)
;;(require 'setup-emacs-eclim)
(require 'setup-programming)
(require 'setup-applications)
(require 'setup-development)
(require 'setup-environment)
(require 'setup-faces-and-ui)
(require 'setup-help)
(require 'setup-helm)
(require 'setup-helm-gtags)
;; (require 'setup-ggtags)
;; (require 'setup-cedet)
(require 'setup-editing)
;;(require 'setup-pyim)

;; make sure that directory snippets needed exists
(insure-dir "~/.emacs.d/snippets")

(helm-autoresize-mode t)


(windmove-default-keybindings)

;; function-args
(require 'function-args)
(fa-config-default)
(define-key c-mode-map  [(control tab)] 'moo-complete)
(define-key c++-mode-map  [(control tab)] 'moo-complete)
(define-key c-mode-map (kbd "M-o")  'fa-show)
(define-key c++-mode-map (kbd "M-o")  'fa-show)

;; company
(require 'company)
(add-hook 'after-init-hook 'global-company-mode)
(delete 'company-semantic company-backends)
;(define-key c-mode-map  [(tab)] 'company-complete)
;(define-key c++-mode-map  [(tab)] 'company-complete)
(define-key c-mode-map  [(control tab)] 'company-complete)
(define-key c++-mode-map  [(control tab)] 'company-complete)

;; company-   c-headers
(add-to-list 'company-backends 'company-c-headers)

;;这一行不能工作，我需要研究一下
;(add-to-list 'company-c-headers-path-system "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk/usr/include/c++/4.2.1/")

;; hs-minor-mode for folding source code
(add-hook 'c-mode-common-hook 'hs-minor-mode)


(global-set-key (kbd "RET") 'newline-and-indent)  ; automatically indent when press RET

;; activate whitespace-mode to view all whitespace characters
(global-set-key (kbd "C-c w") 'whitespace-mode)

;; use space to indent by default
(setq-default indent-tabs-mode nil)

;; set appearance of a tab that is represented by 4 spaces
(setq-default tab-width 4)

;; Compilation
(global-set-key (kbd "<f5>") (lambda ()
                               (interactive)
                               (setq-local compilation-read-command nil)
                               (call-interactively 'compile)))

;; setup GDB
(setq
 ;; use gdb-many-windows by default
 gdb-many-windows t

 ;; Non-nil means display source file containing the main routine at startup
 gdb-show-main t
 )

;; Package: dtrt-indent
(require 'dtrt-indent)
(dtrt-indent-mode 1)

;; Package: yasnippet
(require 'yasnippet)
(yas-global-mode 1)


;; Package zygospore
(global-set-key (kbd "C-x 1") 'zygospore-toggle-delete-other-windows)
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(put 'upcase-region 'disabled nil)
;(setenv "LC_CTYPE" "en_US.UTF-8")
(global-set-key (kbd "C-x w f") 'toggle-frame-maximized)

(defun set-exec-path-from-shell-PATH ()
  (let ((path-from-shell
         (replace-regexp-in-string "[[:space:]\n]*$" ""
                                   (shell-command-to-string "$SHELL -l -c 'echo $PATH'"))))
    (setenv "PATH" path-from-shell)
    (setq exec-path (split-string path-from-shell path-separator))))
(when (equal system-type 'darwin) (set-exec-path-from-shell-PATH))
(put 'narrow-to-region 'disabled nil)

;; (setq mac-option-modifier 'super)
;; (setq mac-command-modifier 'meta)

;; customize frame title, first field show eamcs version
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
;;(setq redisplay-dont-pause nil)
(server-start)

;; set language environment
(set-language-environment 'UTF-8)
(set-locale-environment "UTF-8")
(with-temp-message "")
