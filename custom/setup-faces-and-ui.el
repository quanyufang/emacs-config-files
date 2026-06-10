(provide 'setup-faces-and-ui)

;; you won't need any of the bar thingies
;; turn it off to save screen estate
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (not (eq system-type 'darwin))
    (if (fboundp 'menu-bar-mode) (menu-bar-mode -1)))

;; the blinking cursor is nothing, but an annoyance
(blink-cursor-mode -1)

(setq scroll-margin 0
      scroll-conservatively 100000
      scroll-preserve-screen-position 1)

(size-indication-mode t)

;; more useful frame title, that show either a file or a
;; buffer name (if the buffer isn't visiting a file)
;; taken from prelude-ui.el
(setq frame-title-format
      '("" invocation-name " - " (:eval (if (buffer-file-name)
                                                    (abbreviate-file-name (buffer-file-name))
                                                  "%b"))))

;; change font to Inconsolata for better looking text
;; remember to install the font Inconsolata first
;;(setq default-frame-alist '((font . "Inconsolata-11")))
(if (window-system)
    (if (eq system-type 'darwin)
        (progn
          (set-frame-font "Courier New-13")
          (set-fontset-font
           (frame-parameter nil 'font)
           'han
           (font-spec :family "Hiragino Sans GB" )
           ;;(font-spec :family "Courier New-13")
           ;; set italic font for italic face, since Emacs does not set italic
           ;; face automatically
           (set-face-attribute
                               :family "Inconsolata-Italic")))))


(set-background-color "black")
(set-foreground-color "white")
(set-face-attribute 'default nil :background "black")
(set-face-attribute 'default nil :foreground "white")
;; 设置默认字体大小为20
(set-face-attribute 'default nil :height 200)


(require 'highlight-symbol)

(highlight-symbol-nav-mode)

(add-hook 'text-mode-hook (lambda () (highlight-symbol-mode)))
(add-hook 'org-mode-hook (lambda () (highlight-symbol-mode)))

(setq highlight-symbol-idle-delay 1
      highlight-symbol-on-navigation-p t)

(global-set-key [(control shift mouse-1)]
                (lambda (event)
                  (interactive "e")
                  (goto-char (posn-point (event-start event)))
                  (highlight-symbol-at-point)))

(global-set-key (kbd "M-n") 'highlight-symbol-next)
(global-set-key (kbd "M-p") 'highlight-symbol-prev)

;;(require 'color-theme-sanityinc-tomorrow)
(load-theme 'grandshell t)

;; Fix grandshell-theme: Emacs 30 rejects nil face attributes, must use 'unspecified
;; The theme (last updated 2018) uses nil which now triggers warnings.
;; Guard with facep — sh-heredoc/sh-quoted-exec are only defined in sh-script-mode.
(defun fix-grandshell-faces ()
  "Patch nil face attributes that Emacs 30 rejects."
  (dolist (face-attr '((show-paren-match :background)
                       (header-line :background)
                       (sh-heredoc :foreground)
                       (sh-quoted-exec :foreground)))
    (when (facep (car face-attr))
      (set-face-attribute (car face-attr) nil (cadr face-attr) 'unspecified))))

(when (>= emacs-major-version 30)
  ;; Fix faces that exist at startup
  (fix-grandshell-faces)
  ;; Also fix sh-mode faces when shell scripts are opened
  (add-hook 'sh-mode-hook #'fix-grandshell-faces))

;; define global-font-lock-mode
(setq font-lock-maximum-decoration 4)
