;;; setup-vertico.el --- Modern completion with Vertico + Consult + Embark

(provide 'setup-vertico)

;; Gracefully skip if core packages are not installed
(when (require 'vertico nil t)
(vertico-mode 1)

;; Grow the minibuffer vertically
(setq vertico-resize t)
;; Show more candidates
(setq vertico-count 12)
;; Scroll with C-v/M-v
(setq vertico-scroll-margin 0)
;; Cycle at boundaries
(setq vertico-cycle t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Orderless: flexible matching style  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'orderless)
(setq completion-styles '(orderless basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles partial-completion))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Marginalia: annotations for M-x etc ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'marginalia)
(marginalia-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Consult: enhanced commands          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'consult)

;; C-x b: buffer switching
(global-set-key (kbd "C-x b") 'consult-buffer)

;; C-x C-f: file finding (uses vertico, no change needed but add consult-dir)
(define-key vertico-map (kbd "C-x C-f") 'consult-dir)

;; M-y: browse kill ring
(global-set-key (kbd "M-y") 'consult-yank-from-kill-ring)

;; C-h SPC: jump to mark
(global-set-key (kbd "C-h SPC") 'consult-mark)

;; C-c s: search current buffer (replaces helm-swoop)
(global-set-key (kbd "C-c s") 'consult-line)

;; C-c S: search across project/recursively (replaces helm-multi-swoop)
(global-set-key (kbd "C-c S") 'consult-ripgrep)

;; C-x r j: jump to register (replaces helm-register)
(global-set-key (kbd "C-x r j") 'consult-register)

;; M-g g: go to line
(global-set-key (kbd "M-g g") 'consult-goto-line)
(global-set-key (kbd "M-g M-g") 'consult-goto-line)

;; M-s r: isearch with consult
(define-key isearch-mode-map (kbd "M-s r") 'consult-line)

;; Minibuffer history
(define-key minibuffer-local-map (kbd "M-p") 'previous-history-element)
(define-key minibuffer-local-map (kbd "M-n") 'next-history-element)

;; Eshell history
(add-hook 'eshell-mode-hook
          (lambda ()
            (define-key eshell-mode-map (kbd "M-l") 'consult-eshell-history)))

;; Help integration
(define-key 'help-command (kbd "C-f") 'consult-apropos)
(define-key 'help-command (kbd "r") 'consult-info)

;; Save position before goto-line
(setq consult-point 'preview)

;; Use consult for imenu
(global-set-key (kbd "M-g i") 'consult-imenu)
(global-set-key (kbd "M-g I") 'consult-imenu-multi)

;; consult-ripgrep uses ripgrep if available
(when (executable-find "rg")
  (setq consult-ripgrep-args "rg --null --line-buffered --color=never --max-columns=1000 --path-separator / --smart-case --no-heading --with-filename --line-number --search-zip"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Embark: context-sensitive actions    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'embark)
(require 'embark-consult)

;; C-. : embark act (choose an action for the thing at point/in minibuffer)
(global-set-key (kbd "C-.") 'embark-act)

;; C-; : embark export (for bulk operations)
;; Already used by iedit, so use C-, instead
(global-set-key (kbd "C-,") 'embark-export)

;; C-h B : embark bind (show key bindings for the thing at point)
(global-set-key (kbd "C-h B") 'embark-bindings)

;; Add Embark indicator
(setq embark-indicator 'embark-minimal-indicator)

;; Show verbose indicator in minibuffer
(setq embark-verbose-indicator-display-action
      '(display-buffer-at-bottom
        (window-height . fit-window-to-buffer)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Wgrep: edit grep results inline      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'wgrep)
(setq wgrep-auto-save-buffer t)
(setq wgrep-enable-key "r")  ; C-c C-p r to enter wgrep mode

;;; keybinding summary:
;;; ┌──────────────┬─────────────────────────────────────┐
;;; │ Key          │ Function                            │
;;; ├──────────────┼─────────────────────────────────────┤
;;; │ M-x          │ execute-extended-command (vertico)   │
;;; │ C-x b        │ consult-buffer                      │
;;; │ C-x C-f      │ find-file (vertico enhanced)        │
;;; │ M-y          │ consult-yank-from-kill-ring          │
;;; │ C-h SPC      │ consult-mark                        │
;;; │ C-c s        │ consult-line (search buffer)         │
;;; │ C-c S        │ consult-ripgrep (search project)     │
;;; │ C-x r j      │ consult-register                    │
;;; │ M-g g        │ consult-goto-line                   │
;;; │ M-g i        │ consult-imenu                       │
;;; │ C-.          │ embark-act                          │
;;; │ C-h B        │ embark-bindings                     │
;;; │ C-h C-f      │ consult-apropos                     │
;;; │ C-h r        │ consult-info                        │
;;; └──────────────┴─────────────────────────────────────┘

)  ; end of when vertico is available