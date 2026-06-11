;;; setup-inline-crypt.el --- Inline text encryption with GPG for any buffer
;;
;; Usage:
;;   C-c e   - encrypt selected region (→ 🔐 collapsed indicator)
;;   C-c d   - decrypt block at point (→ plaintext, editable)
;;   C-x C-s - save: re-encrypts any decrypted blocks (→ back to 🔐)
;;
;; Encrypted blocks are wrapped in delimiters (stored collapsed as 🔐):
;;   org-mode:  #+BEGIN_gpg ... #+END_gpg
;;   markdown:  <!--gpg: ... -->
;;   otherwise: ----BEGIN PGP MESSAGE---- ... ----END PGP MESSAGE----
;;
;; The full PGP ciphertext is hidden behind a 🔐 indicator.
;; Use C-c d on 🔐 to decrypt and view/edit the content.
;; Set `inline-crypt-collapse-encrypted' to nil to show the full ciphertext.

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

;;; Collapse encrypted blocks (compact display)
(defcustom inline-crypt-collapse-encrypted t
  "When non-nil, collapse encrypted blocks to a compact lock indicator.
The full PGP message text is hidden behind a short indicator string.
Use `C-c d' on the indicator to decrypt and reveal the content."
  :type 'boolean
  :group 'inline-crypt)

(defcustom inline-crypt-collapsed-indicator " 🔐 "
  "String displayed in place of collapsed encrypted blocks."
  :type 'string
  :group 'inline-crypt)

;;; Encrypted block faces
(defface inline-crypt-encrypted-face
  '((t (:background "#2d1a3a" :foreground "#b39ddb" :extend t)))
  "Face for encrypted text blocks (full display)."
  :group 'inline-crypt)

(defface inline-crypt-decrypted-face
  '((t (:background "#1a3a2d" :foreground "#81c784" :extend t)))
  "Face for temporarily decrypted text blocks."
  :group 'inline-crypt)

(defface inline-crypt-collapsed-face
  '((t (:background "#4a3570" :foreground "#d0c0ff" :weight bold
        :box (:line-width 1 :color "#8b6fc0"))))
  "Face for the collapsed encrypted block indicator.
Looks like a compact tag/label in the text."
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

;;; ── Collapse / expand helpers ───────────────────────────────

(defun inline-crypt--collapsed-at-point ()
  "Return (beg . end) of the collapsed indicator at point, or nil."
  (let ((pos (point)))
    (cond
     ((get-text-property pos 'inline-crypt-collapsed)
      (let ((beg (previous-single-property-change (1+ pos) 'inline-crypt-collapsed))
            (end (next-single-property-change pos 'inline-crypt-collapsed)))
        (cons (or beg (point-min)) (or end (point-max)))))
     ;; Check if point is just before a collapsed indicator
     ((and (< pos (point-max))
           (get-text-property (1+ pos) 'inline-crypt-collapsed))
      (inline-crypt--collapsed-at-point))
     ;; Check if point is just after a collapsed indicator
     ((and (> pos (point-min))
           (get-text-property (1- pos) 'inline-crypt-collapsed))
      (inline-crypt--collapsed-at-point)))))

(defun inline-crypt--expand-block (beg end)
  "Remove the display property at BEG..END to reveal the underlying PGP block.
Returns (new-beg . new-end) of the expanded PGP block, or nil on failure."
  (when (get-text-property beg 'inline-crypt-collapsed)
    (with-silent-modifications
      (remove-text-properties beg end '(display nil inline-crypt-collapsed nil read-only nil keymap nil))
      (add-text-properties beg end
                           '(face inline-crypt-encrypted-face
                             font-lock-face inline-crypt-encrypted-face
                             inline-crypt-hidden t)))
    (cons beg end)))

(defun inline-crypt--collapse-block (beg end)
  "Hide the encrypted block at BEG..END behind a lock indicator.
Uses the `display' text property so the underlying ciphertext remains in the buffer.
This is non-destructive: the original text is preserved for saving."
  (when inline-crypt-collapse-encrypted
    (let ((keymap (let ((map (make-sparse-keymap)))
                    (define-key map (kbd "C-c d") #'inline-crypt-decrypt-at-point)
                    map)))
      (with-silent-modifications
        (add-text-properties
         beg end
         `(face inline-crypt-collapsed-face
           font-lock-face inline-crypt-collapsed-face
           inline-crypt-collapsed t
           inline-crypt-hidden t
           read-only t
           keymap ,keymap
           display ,inline-crypt-collapsed-indicator
           help-echo "Encrypted text — C-c d to decrypt"))))))

;;; ── Scan and collapse existing blocks ────────────────────────

(defun inline-crypt--collapse-all-in-buffer ()
  "Find all plain PGP blocks in the buffer and collapse them."
  (interactive)
  (when inline-crypt-collapse-encrypted
    (save-excursion
      (goto-char (point-min))
      (let ((count 0))
        (while (re-search-forward "-----BEGIN PGP MESSAGE-----" nil t)
          ;; Check this isn't already inside a collapsed block
          (unless (get-text-property (point) 'inline-crypt-collapsed)
            (let ((block (inline-crypt--find-block-bounds)))
              (when block
                (inline-crypt--collapse-block (car block) (cdr block))
                (setq count (1+ count))))))
        (when (> count 0)
          (message "Collapsed %d encrypted block(s)." count))))))

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
      (unless (string-empty-p (car delims))
        (insert (car delims) "\n"))
      (insert encrypted)
      (unless (string-empty-p (cdr delims))
        (insert "\n" (cdr delims))))
    ;; Apply encrypted face, then collapse
    (let ((block (inline-crypt--find-block-bounds)))
      (when block
        (add-text-properties (car block) (cdr block)
                             '(face inline-crypt-encrypted-face
                               font-lock-face inline-crypt-encrypted-face))
        (inline-crypt--collapse-block (car block) (cdr block))))
    (message "Text encrypted (%d chars → %d chars). %s to decrypt."
             (length plaintext) (length encrypted)
             (if inline-crypt-collapse-encrypted
                 "C-c d on 🔐"
               "C-c d"))))

;;; ── Decrypt block at point ─────────────────────────────────

;;;###autoload
(defun inline-crypt-decrypt-at-point ()
  "Decrypt the encrypted block at point, replacing it with plaintext.
If point is on a collapsed 🔐 indicator, expand it first before decrypting.
The plaintext is tracked so it can be re-encrypted before saving."
  (interactive)
  (unless (executable-find "gpg")
    (user-error "GPG not found.  Install with: brew install gnupg"))
  ;; If point is on a collapsed indicator, expand it first
  (let ((collapsed (inline-crypt--collapsed-at-point)))
    (when collapsed
      (let ((expanded (inline-crypt--expand-block (car collapsed) (cdr collapsed))))
        (unless expanded
          (user-error "Failed to expand collapsed block"))
        (goto-char (cdr expanded)))))  ; jump to END so backward search finds PGP header
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
               (user-error "Decryption failed: %s"
                           (error-message-string err))))))
      ;; Replace PGP block with plaintext (bypass read-only)
      (let ((inhibit-read-only t))
        (delete-region beg end)
        (insert plaintext))
      (let ((ins-pos beg))
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
                      ;; Find and collapse the newly inserted block
                      (let ((new-block (inline-crypt--find-block-bounds)))
                        (when new-block
                          (add-text-properties
                           (car new-block) (cdr new-block)
                           '(face inline-crypt-encrypted-face
                             font-lock-face inline-crypt-encrypted-face))
                          (inline-crypt--collapse-block (car new-block) (cdr new-block))))
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
      (progn
        (add-hook 'before-save-hook #'inline-crypt--reencrypt-before-save nil t)
        ;; Collapse any existing PGP blocks in the buffer
        (run-with-idle-timer 0.1 nil #'inline-crypt--collapse-all-in-buffer))
    (remove-hook 'before-save-hook #'inline-crypt--reencrypt-before-save t))
  ;; Also hook into org-ctrl-c-ctrl-c to decrypt an org block easily
  (when (derived-mode-p 'org-mode)
    (if inline-crypt-mode
        (add-hook 'org-ctrl-c-ctrl-c-hook #'inline-crypt--org-ctrl-c-ctrl-c nil t)
      (remove-hook 'org-ctrl-c-ctrl-c-hook #'inline-crypt--org-ctrl-c-ctrl-c t))))

(defun inline-crypt--org-ctrl-c-ctrl-c ()
  "If point is on an inline-crypt block (or collapsed 🔐), decrypt it.
For `org-ctrl-c-ctrl-c'."
  (when (or (inline-crypt--find-block-bounds)
            (inline-crypt--collapsed-at-point))
    (inline-crypt-decrypt-at-point)
    t))  ; return t to indicate we handled it

;;; ── Enable in relevant modes by default ────────────────────
(add-hook 'org-mode-hook #'inline-crypt-mode)
(add-hook 'markdown-mode-hook #'inline-crypt-mode)
(add-hook 'text-mode-hook #'inline-crypt-mode)