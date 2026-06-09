(provide 'setup-external)

;; ;; GROUP: Processes -> Flyspell
;; (if (executable-find "aspell")
;;     (progn
;;       (setq ispell-program-name "aspell")
;;       (setq ispell-extra-args '("--sug-mode=ultra")))
;;   (setq ispell-program-name "ispell"))

;; (add-hook 'text-mode-hook 'flyspell-mode)
;; (add-hook 'org-mode-hook 'flyspell-mode)
;; (add-hook 'prog-mode-hook 'flyspell-prog-mode)

;; term-mode, used in M-x term
(defun my-term-setup ()
  (interactive)
  (define-key term-raw-map (kbd "C-y") 'term-send-raw)
  (define-key term-raw-map (kbd "C-p") 'term-send-raw)
  (define-key term-raw-map (kbd "C-n") 'term-send-raw)
  (define-key term-raw-map (kbd "C-s") 'term-send-raw)
  (define-key term-raw-map (kbd "C-r") 'term-send-raw)
  (define-key term-raw-map (kbd "M-w") 'kill-ring-save)
  (define-key term-raw-map (kbd "M-y") 'helm-show-kill-ring)
  (define-key term-raw-map (kbd "M-d") (lambda () (interactive) (term-send-raw-string "\ed")))
  (define-key term-raw-map (kbd "<C-backspace>") (lambda () (interactive) (term-send-raw-string "\e\C-?")))
  (define-key term-raw-map (kbd "M-p") (lambda () (interactive) (term-send-raw-string "\ep")))
  (define-key term-raw-map (kbd "M-n") (lambda () (interactive) (term-send-raw-string "\en")))
  (define-key term-raw-map (kbd "M-,") 'term-send-input)
  (define-key term-raw-map (kbd "C-c y") 'term-paste)
  (define-key term-raw-map (kbd "C-S-y") 'term-paste)
  (define-key term-raw-map (kbd "C-h") nil) ; unbind C-h
  (define-key term-raw-map (kbd "M-x") nil) ; unbind M-x
  (define-key term-raw-map (kbd "C-c C-b") 'helm-mini)
  (define-key term-raw-map (kbd "C-1") 'zygospore-toggle-delete-other-windows)
  (define-key term-raw-map (kbd "C-2") 'split-window-below)
  (define-key term-raw-map (kbd "C-3") 'split-window-right)
  (define-key term-mode-map (kbd "C-0") 'delete-window))
(add-hook 'term-mode-hook 'my-term-setup t)
(setq term-buffer-maximum-size 0)

(require 'term)

;; taken from here: http://www.enigmacurry.com/2008/12/26/emacs-ansi-term-tricks/
(defun visit-ansi-term ()
  "If the current buffer is:
     1) a running ansi-term named *ansi-term*, rename it.
     2) a stopped ansi-term, kill it and create a new one.
     3) a non ansi-term, go to an already running ansi-term
        or start a new one while killing a defunt one"
  (interactive)
  (let ((is-term (string= "term-mode" major-mode))
        (is-running (term-check-proc (buffer-name)))
        (term-cmd "/bin/zsh")
        (anon-term (get-buffer "*ansi-term*")))
    (if is-term
        (if is-running
            (if (string= "*ansi-term*" (buffer-name))
                ;; (call-interactively 'rename-buffer)
                (ansi-term term-cmd)
              (if anon-term
                  (switch-to-buffer "*ansi-term*")
                (ansi-term term-cmd)))
          (kill-buffer (buffer-name))
          (ansi-term term-cmd))
      (if anon-term
          (if (term-check-proc "*ansi-term*")
              (switch-to-buffer "*ansi-term*")
            (kill-buffer "*ansi-term*")
            (ansi-term term-cmd))
        (ansi-term term-cmd)))))

(global-set-key (kbd "<f2>") 'visit-ansi-term)

;; PACKAGE: shell-pop
;; GROUP: Processes -> Shell -> Shell Pop
(require 'shell-pop)
(global-set-key (kbd "C-c t") 'shell-pop)
