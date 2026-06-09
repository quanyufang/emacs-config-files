(provide 'setup-applications)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GROUP: Applications-> Eshell       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'eshell)
(require 'em-alias)

;; Accept a list of files for find-file-other-window
(defun find-files-around (orig-fun filename &rest args)
  "Call `find-file-other-window' for each file in a list."
  (if (listp filename)
      (dolist (f filename)
        (apply orig-fun f args))
    (apply orig-fun filename args)))

(advice-add 'find-file-other-window :around #'find-files-around)

;; In Eshell, you can run the commands in M-x
;; Here are the aliases to the commands.
;; $* means accepts all arguments.
(eshell/alias "o" "")
(eshell/alias "o" "find-file-other-window $*")
(eshell/alias "vi" "find-file-other-window $*")
(eshell/alias "vim" "find-file-other-window $*")
(eshell/alias "emacs" "find-file-other-windpow $*")
(eshell/alias "em" "find-file-other-window $*")

(add-hook
 'eshell-mode-hook
 (lambda ()
   (setq pcomplete-cycle-completions nil)))

;;  ls command switches, in OS X and Linux/Unix are different
(when (not (eq system-type 'windows-nt))
  (if (eq system-type 'darwin)
      (eshell/alias "ls" "ls -lahG $*")
    (eshell/alias "ls" "ls --color -h --group-directories-first $*")))
