(provide 'setup-applications)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GROUP: Applications-> Eshell       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'eshell)
(require 'em-alias)
(require 'cl)

;; Advise find-file-other-window to accept more than one file
(defadvice find-file-other-window (around find-files activate)
  "Also find all files within a list of files. This even works recursively."
  (if (listp filename)
      (cl-loop for f in filename do (find-file-other-window f wildcards))
    ad-do-it))

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
