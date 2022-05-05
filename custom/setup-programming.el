(provide 'setup-programming)
;; GROUP: Programming -> Languages -> C

;; Available C style:
;; “gnu”: The default style for GNU projects
;; “k&r”: What Kernighan and Ritchie, the authors of C used in their book
;; “bsd”: What BSD developers use, aka “Allman style” after Eric Allman.
;; “whitesmith”: Popularized by the examples that came with Whitesmiths C, an early commercial C compiler.
;; “stroustrup”: What Stroustrup, the author of C++ used in his book
;; “ellemtel”: Popular C++ coding standards as defined by “Programming in C++, Rules and Recommendations,” Erik Nyquist and Mats Henricson, Ellemtel
;; “linux”: What the Linux developers use for kernel development
;; “python”: What Python developers use for extension modules
;; “java”: The default style for java-mode (see below)
;; “user”: When you want to define your own style
(setq c-default-style "linux" ; set style to "linux"
      c-basic-offset 4)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GROUP: Programming -> Tools -> Gdb ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setq gdb-many-windows t        ; use gdb-many-windows by default
      gdb-show-main t)          ; Non-nil means display source file containing the main routine at startup

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GROUP: Programming -> Tools -> Compilation ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Compilation from Emacs
(defun prelude-colorize-compilation-buffer ()
  "Colorize a compilation mode buffer."
  (interactive)
  ;; we don't want to mess with child modes such as grep-mode, ack, ag, etc
  (when (eq major-mode 'compilation-mode)
    (let ((inhibit-read-only t))
      (ansi-color-apply-on-region (point-min) (point-max)))))

;; setup compilation-mode used by `compile' command
(require 'compile)
(setq compilation-ask-about-save nil          ; Just save before compiling
      compilation-always-kill t               ; Just kill old compile processes before starting the new one
      compilation-scroll-output 'first-error) ; Automatically scroll to first
(global-set-key (kbd "<f5>") 'compile)

;; GROUP: Programming -> Tools -> Makefile
;; takenn from prelude-c.el:48: https://github.com/bbatsov/prelude/blob/master/modules/prelude-c.el
(defun prelude-makefile-mode-defaults ()
  (whitespace-toggle-options '(tabs))
  (setq indent-tabs-mode t ))

(setq prelude-makefile-mode-hook 'prelude-makefile-mode-defaults)

(add-hook 'makefile-mode-hook (lambda ()
                                (run-hooks 'prelude-makefile-mode-hook)))

;; GROUP: Programming -> Tools -> Ediff
(setq ediff-diff-options "-w"
      ediff-split-window-function 'split-window-horizontally
      ediff-window-setup-function 'ediff-setup-windows-plain)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PACKAGE: diff-hl                             ;;
;;                                              ;;
;; GROUP: Programming -> Tools -> Vc -> Diff Hl ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(global-diff-hl-mode)
(add-hook 'dired-mode-hook 'diff-hl-dired-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PACKAGE: magit                       ;;
;;                                      ;;
;; GROUP: Programming -> Tools -> Magit ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;(require 'magit)
;;(set-default 'magit-stage-all-confirm nil)
;;(add-hook 'magit-mode-hook 'magit-load-config-extensions)

;; full screen magit-status
(defadvice magit-status (around magit-fullscreen activate)
  (window-configuration-to-register :magit-fullscreen)
  ad-do-it
  (delete-other-windows))

(global-unset-key (kbd "C-x g"))
(global-set-key (kbd "C-x g h") 'magit-log)
(global-set-key (kbd "C-x g f") 'magit-file-log)
(global-set-key (kbd "C-x g b") 'magit-blame-mode)
(global-set-key (kbd "C-x g m") 'magit-branch-manager)
(global-set-key (kbd "C-x g c") 'magit-branch)
(global-set-key (kbd "C-x g s") 'magit-status)
(global-set-key (kbd "C-x g r") 'magit-reflog)
(global-set-key (kbd "C-x g t") 'magit-tag)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PACKAGE: flycheck                       ;;
;;                                         ;;
;; GROUP: Programming -> Tools -> Flycheck ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'flycheck)
;(add-hook 'after-init-hook #'global-flycheck-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PACKAGE: flycheck-tip                                      ;;
;;                                                            ;;
;; GROUP: Flycheck Tip, but just consider it part of Flycheck ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;(require 'flycheck-tip)
;;(flycheck-tip-use-timer 'verbose)


;; Package: clean-aindent-mode
(require 'clean-aindent-mode)
(add-hook 'prog-mode-hook 'clean-aindent-mode)

;; Package: ws-butler
(require 'ws-butler)
(add-hook 'prog-mode-hook 'ws-butler-mode)

;; psvn
;;(require 'psvn)


(add-hook 'prog-mode-hook 'helm-gtags-mode)
;;C/C++

;; php
(require 'php-mode)
(add-to-list 'auto-mode-alist '("\\.php\\'" . php-mode))
(add-hook 'php-mode-hook
          (lambda()
            (anzu-mode -1)
            (clean-aindent-mode -1)
            (column-enforce-mode -1)
            (delete-selection-mode -1)
            (diff-auto-refine-mode -1)
            (diff-hl-mode -1)
            (file-name-shadow-mode -1)
            (function-args-mode -1)
            (global-anzu-mode -1)
            ;; (ede-minor-mode -1)
            ;; (global-ede-mode -1)
            (eldoc-mode -1)
            (global-semantic-idle-scheduler-mode -1)
            (global-semantic-stickyfunc-mode -1)
            (global-semanticdb-minor-mode -1)
            (goto-address-mode -1)
            (helm-mode -1)
            (helm-autoresize-mode -1)
            (helm-gtags-mode -1)
            (semantic-mode -1)
            (workgroups-mode -1)
            (c-set-style "php")
            (define-key php-mode-map (kbd "C-c g a") 'helm-gtags-tags-in-this-function)
            (define-key php-mode-map (kbd "C-j") 'helm-gtags-select)
            (define-key php-mode-map (kbd "M-.") 'helm-gtags-dwim)
            (define-key php-mode-map (kbd "M-,") 'helm-gtags-pop-stack)
            (define-key php-mode-map (kbd "M-*") 'helm-gtags-find-rtag)
            (define-key php-mode-map (kbd "C-c <") 'helm-gtags-previous-history)
            (define-key php-mode-map (kbd "C-c >") 'helm-gtags-next-history)
            ))
;;(require 'php-auto-yasnippets)
;;(setq php-auto-yasnippets-path "~/.emacs.d/elpa/php-auto-yasnippets-20141128.1411")
;;(setq php-auto-yasnippet-php-program (concat php-auto-yasnippets-path "/Create-PHP-YASnippet.php"))
;;(define-key php-mode-map (kbd "C-c C-y") 'yas/create-php-snippet)

;; python
(require 'python)
(defun run-python-once ()
  (remove-hook 'python-mode-hook 'run-python-once)
  (python-shell-get-or-create-process))
(defun jedi-config:setup-keys ()
  (local-set-key (kbd "M-.") 'jedi:goto-definition)
  (local-set-key (kbd "M-,") 'jedi:goto-definition-pop-marker)
  (local-set-key (kbd "M-?") 'jedi:show-doc)
  (local-set-key (kbd "M-/") 'jedi:get-in-function-call))

(add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))
(autoload 'jedi:setup "jedi" nil t)
(setq jedi:setup-keys t)
(add-hook 'python-mode-hook 'jedi-config:setup-keys)
(add-hook 'python-mode-hook 'jedi:setup)
(add-hook 'python-mode-hook 'run-python-once)
(setq jedi:complete-on-dot t)

;; emacs-lisp-mode
;; lisp  can only use etags
(defun elisp-setup-keys ()
  (local-set-key (kbd "M-.") 'find-tag)
  (local-set-key (kbd "M-,") 'pop-tag-mark)
  )
(add-hook 'emacs-lisp-mode-hook 'elisp-setup-keys)

;; slime
(require 'slime)
(setq inferior-lisp-program "/usr/local/bin/sbcl")
(slime-setup '(slime-fancy slime-banner))
(require 'slime-autoloads)
(require 'slime-company)

;;java
(add-hook 'java-mode-hook
          (lambda()
            (define-key java-mode-map (kbd "C-c g a") 'helm-gtags-tags-in-this-function)
            (define-key java-mode-map (kbd "C-j") 'helm-gtags-select)
            (define-key java-mode-map (kbd "M-.") 'helm-gtags-dwim)
            (define-key java-mode-map (kbd "M-,") 'helm-gtags-pop-stack)
            (define-key java-mode-map (kbd "M-*") 'helm-gtags-find-rtag)
            (define-key java-mode-map (kbd "C-c <") 'helm-gtags-previous-history)
            (define-key java-mode-map (kbd "C-c >") 'helm-gtags-next-history)
            ))


(add-hook 'prog-mode-hook 'column-enforce-mode)
(setq column-enforce-column 120)
