;;; setup-inline-crypt.el --- Inline text encryption with GPG for any buffer
;;
;; Usage:
;;   C-c e   - encrypt selected region (→ PGP block)
;;   C-c d   - decrypt PGP block at point (→ plaintext, editable)
;;
;; Encrypted blocks are wrapped in delimiters:
;;   org-mode:  #+BEGIN_gpg ... #+END_gpg
;;   markdown:  <!--gpg: ... -->
;;   otherwise: ----BEGIN PGP MESSAGE---- ... ----END PGP MESSAGE----

(provide 'setup-inline-crypt)

(require 'epa)

(defgroup inline-crypt nil
  "Inline text encryption with GPG."
  :group 'editing)

(defcustom inline-crypt-gpg-key nil
  "GPG key ID to use for encryption.  nil = use default key."
  :type '(choice (const :tag "Default key" nil)
                 (string :tag "Key ID"))
  :group 'inline-crypt)

(defcustom inline-crypt-org-delimiter-begin "#+BEGIN_gpg"
  "Opening delimiter for encrypted blocks in org-mode."
  :type 'string
  :group 'inline-crypt)

(defcustom inline-crypt-org-delimiter-end "#+END_gpg"
  "Closing delimiter for encrypted blocks in org-mode."
  :type 'string
  :group 'inline-crypt)

(defcustom inline-crypt-md-delimiter-begin "<!--gpg:"
  "Opening delimiter for encrypted blocks in markdown."
  :type 'string
  :group 'inline-crypt)

(defcustom inline-crypt-md-delimiter-end ":-->"
  "Closing delimiter for encrypted blocks in markdown."
  :type 'string
  :group 'inline-crypt)

;;; Encrypted block face
(defface inline-crypt-encrypted-face
  '((t (:background "#2d1a3a" :foreground "#b39ddb" :extend t)))
  "Face for encrypted text blocks."
  :group 'inline-crypt)

(defface inline-crypt-decrypted-face
  '((t (:background "#1a3a2d" :foreground "#81c784" :extend t)))
  "Face for temporarily decrypted text blocks."
  :group 'inline-crypt)

;;; ── Delimiter helpers ──────────────────────────────────────

(defun inline-crypt--delimiters ()
  "Return (begin-delim . end-delim) for the current buffer."
  (cond
   ((derived-mode-p 'org-mode)
    (cons inline-crypt-org-delimiter-begin inline-crypt-org-delimiter-end))
   ((derived-mode-p 'markdown-mode)
    (cons inline-crypt-md-delimiter-begin inline-crypt-md-delimiter-end))
   (t
    (cons "" ""))))  ; raw PGP armor, no extra delimiters

(defun inline-crypt--armor-beg-re ()
  "Regex to find beginning of an inline-crypt encrypted block."
  (concat
   "\\(" (regexp-quote inline-crypt-org-delimiter-begin) "\n\\)?"
   "-----BEGIN PGP MESSAGE-----"))

(defun inline-crypt--armor-end-re ()
  "Regex to find end of an inline-crypt encrypted block."
  (concat "-----END PGP MESSAGE-----"
          "\\(?:\n" (regexp-quote inline-crypt-org-delimiter-end) "\\)?"))

;;; ── Find encrypted block at point ──────────────────────────

(defun inline-crypt--find-block-bounds ()
  "Return (beg . end) of the encrypted block at point, or nil."
  (save-excursion
    (let ((orig (point))
          beg end)
      ;; Search backward for start of PGP message
      (when (re-search-backward "-----BEGIN PGP MESSAGE-----" nil t)
        (setq beg (point))
        ;; Check for org delimiter before it
        (save-excursion
          (goto-char (line-beginning-position))
          (when (looking-at-p (regexp-quote inline-crypt-org-delimiter-begin))
            (setq beg (point))))
        ;; Search forward for end of PGP message
        (goto-char beg)
        (when (re-search-forward "-----END PGP MESSAGE-----" nil t)
          (setq end (point))
          ;; Check for org delimiter after it
          (when (and (derived-mode-p 'org-mode)
                     (looking-at-p (concat "\n" (regexp-quote inline-crypt-org-delimiter-end))))
            (goto-char end)
            (forward-line 1)
            (setq end (point)))
          ;; Check if original point was inside this block
          (when (and (<= beg orig) (<= orig end))
            (cons beg end)))))))

;;; ── Track decrypted blocks for re-encryption on save ───────

(defvar-local inline-crypt--decrypted-blocks nil
  "Alist of ((beg . end) . plaintext) for blocks decrypted in this buffer.")

(defun inline-crypt--register-decrypted (beg end plaintext)
  "Register a decrypted block so it can be re-encrypted before save."
  (push (cons (cons beg end) plaintext) inline-crypt--decrypted-blocks))

;;; ── Encrypt region ─────────────────────────────────────────

;;;###autoload
(defun inline-crypt-encrypt-region (beg end)
  "Encrypt the selected region with GPG and replace with an encrypted block."
  (interactive "r")
  (unless (executable-find "gpg")
    (user-error "GPG not found.  Install with: brew install gnupg"))
  (unless (region-active-p)
    (user-error "No region selected"))
  (let* ((plaintext (buffer-substring-no-properties beg end))
         (context (epg-make-context 'OpenPGP))
         (keys (ignore-errors (epg-list-keys context inline-crypt-gpg-key)))
         (encrypted (epg-encrypt-string context plaintext
                                        (or keys (epg-list-keys context)))))
    (unless encrypted
      (user-error "Encryption failed. Check GPG key availability"))
    (delete-region beg end)
    (let ((delims (inline-crypt--delimiters)))
      (when (string-empty-p (car delims))
        (insert (car delims) "\n"))
      (insert encrypted)
      (when (string-empty-p (cdr delims))
        (insert "\n" (cdr delims))))
    ;; Apply encrypted face
    (let ((block (inline-crypt--find-block-bounds)))
      (when block
        (add-text-properties (car block) (cdr block)
                             '(face inline-crypt-encrypted-face
                               font-lock-face inline-crypt-encrypted-face))))
    (message "Text encrypted (%d chars → %d chars). C-c d to decrypt."
             (length plaintext) (length encrypted))))

;;; ── Decrypt block at point ─────────────────────────────────

;;;###autoload
(defun inline-crypt-decrypt-at-point ()
  "Decrypt the encrypted block at point, replacing it with plaintext.
The plaintext is tracked so it can be re-encrypted before saving."
  (interactive)
  (unless (executable-find "gpg")
    (user-error "GPG not found.  Install with: brew install gnupg"))
  (let* ((bounds (inline-crypt--find-block-bounds))
         (beg (car bounds))
         (end (cdr bounds)))
    (unless bounds
      (user-error "No encrypted block found at point"))
    ;; Extract and decrypt
    (let* ((armor (buffer-substring-no-properties beg end))
           (context (epg-make-context 'OpenPGP))
           (plaintext
            (condition-case err
                (epg-decrypt-string context armor)
              (error
               (user-error "Decryption failed: %s" (error-message-string err))))))
      ;; Replace with plaintext
      (delete-region beg end)
      (let ((ins-pos (point)))
        (insert plaintext)
        ;; Register for re-encryption on save
        (inline-crypt--register-decrypted ins-pos (point) plaintext)
        ;; Apply decrypted face
        (add-text-properties ins-pos (point)
                             `(face inline-crypt-decrypted-face
                               font-lock-face inline-crypt-decrypted-face
                               inline-crypt-decrypted t))
        (message "Text decrypted (%d chars). Edit then save to re-encrypt."
                 (length plaintext))
        ;; Position cursor at beginning of decrypted text
        (goto-char ins-pos)))))

;;; ── Auto re-encrypt on save ────────────────────────────────

(defun inline-crypt--reencrypt-before-save ()
  "Re-encrypt any decrypted blocks before saving the buffer."
  (when inline-crypt--decrypted-blocks
    (let ((re-encrypted 0))
      (dolist (entry (reverse inline-crypt--decrypted-blocks))
        (let* ((bounds (car entry))
               (old-plaintext (cdr entry))
               (beg (car bounds))
               (end (cdr bounds)))
          (when (and (<= beg (point-max)) (<= end (point-max)))
            (let ((current-text (buffer-substring-no-properties beg end)))
              ;; Only re-encrypt if the text hasn't been modified beyond recognition
              (when (and current-text
                         (> (length current-text) 0))
                (let* ((context (epg-make-context 'OpenPGP))
                       (keys (ignore-errors
                               (epg-list-keys context inline-crypt-gpg-key)))
                       (encrypted (epg-encrypt-string
                                   context current-text
                                   (or keys (epg-list-keys context)))))
                  (when encrypted
                    (delete-region beg end)
                    (let ((delims (inline-crypt--delimiters))
                          (ins-pos (point)))
                      (unless (string-empty-p (car delims))
                        (insert (car delims) "\n"))
                      (insert encrypted)
                      (unless (string-empty-p (cdr delims))
                        (insert "\n" (cdr delims)))
                      (add-text-properties
                       ins-pos (point)
                       `(face inline-crypt-encrypted-face
                         font-lock-face inline-crypt-encrypted-face))
                      (setq re-encrypted (1+ re-encrypted))))))))))
      (setq inline-crypt--decrypted-blocks nil)
      (when (> re-encrypted 0)
        (message "Re-encrypted %d block(s) before save." re-encrypted)))))

;;; ── Minor mode ─────────────────────────────────────────────

;;;###autoload
(define-minor-mode inline-crypt-mode
  "Toggle inline text encryption capability.
When enabled:
  \\[inline-crypt-encrypt-region] - encrypt selected region
  \\[inline-crypt-decrypt-at-point] - decrypt block at point

Encrypted blocks are re-encrypted automatically when saving the buffer."
  :lighter " 🔒"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c e") #'inline-crypt-encrypt-region)
            (define-key map (kbd "C-c d") #'inline-crypt-decrypt-at-point)
            map)
  (if inline-crypt-mode
      (add-hook 'before-save-hook #'inline-crypt--reencrypt-before-save nil t)
    (remove-hook 'before-save-hook #'inline-crypt--reencrypt-before-save t))
  ;; Also hook into org-ctrl-c-ctrl-c to decrypt an org block easily
  (when (derived-mode-p 'org-mode)
    (if inline-crypt-mode
        (add-hook 'org-ctrl-c-ctrl-c-hook #'inline-crypt--org-ctrl-c-ctrl-c nil t)
      (remove-hook 'org-ctrl-c-ctrl-c-hook #'inline-crypt--org-ctrl-c-ctrl-c t))))

(defun inline-crypt--org-ctrl-c-ctrl-c ()
  "If point is on an inline-crypt block, decrypt it.  For `org-ctrl-c-ctrl-c'."
  (when (inline-crypt--find-block-bounds)
    (inline-crypt-decrypt-at-point)
    t))  ; return t to indicate we handled it

;;; ── Enable in relevant modes by default ────────────────────
(add-hook 'org-mode-hook #'inline-crypt-mode)
(add-hook 'markdown-mode-hook #'inline-crypt-mode)
(add-hook 'text-mode-hook #'inline-crypt-mode)