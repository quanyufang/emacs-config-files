;;; setup-inline-crypt.el --- Inline text encryption with GPG for any buffer
;;
;; Usage:
;;   C-c e   - encrypt selected region (→ 🔐 collapsed indicator)
;;   C-c v   - toggle lock indicator ↔ visible ciphertext (no decryption)
;;   C-c d   - decrypt block at point (→ plaintext, editable)
;;   C-c r   - relock unchanged decrypted block (→ 🔐, no file change)
;;   C-x C-s - save: re-encrypt modified blocks (→ 🔐 with new ciphertext)
;;
;; Encrypted blocks are wrapped in delimiters (stored collapsed as 🔐):
;;   org-mode:  #+BEGIN_gpg ... #+END_gpg
;;   markdown:  <!--gpg: ... -->
;;   otherwise: ----BEGIN PGP MESSAGE---- ... ----END PGP MESSAGE----
;;
;; Set `inline-crypt-collapse-encrypted' to nil to disable the lock indicator.

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

(defun inline-crypt--opening-delimiter-at-point ()
  "Return buffer position of mode-specific opening delimiter near point, or nil.
Checks the current line and the line immediately above."
  (save-excursion
    (goto-char (line-beginning-position))
    (let ((check
           (lambda ()
             (cond
              ((and (derived-mode-p 'org-mode)
                    (looking-at-p (regexp-quote inline-crypt-org-delimiter-begin)))
               (point))
              ((and (derived-mode-p 'markdown-mode)
                    (looking-at-p (regexp-quote inline-crypt-md-delimiter-begin)))
               (point))
              (t nil)))))
      (or (funcall check)
          (when (> (line-number-at-pos) 1)
            (forward-line -1)
            (goto-char (line-beginning-position))
            (funcall check))))))

(defun inline-crypt--extend-end-for-closing-delimiter (end)
  "If a mode-specific closing delimiter follows END, return position after it."
  (cond
   ((and (derived-mode-p 'org-mode)
         (looking-at-p (concat "\n" (regexp-quote inline-crypt-org-delimiter-end))))
    (goto-char end)
    (forward-line 1)
    (point))
   ((and (derived-mode-p 'markdown-mode)
         (looking-at-p (concat "\n" (regexp-quote inline-crypt-md-delimiter-end))))
    (goto-char end)
    (forward-line 1)
    (point))
   (t end)))

(defun inline-crypt--make-collapsed-keymap ()
  "Keymap for collapsed encrypted blocks."
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c d") #'inline-crypt-decrypt-at-point)
    (define-key map (kbd "C-c v") #'inline-crypt-toggle-armor-visibility)
    map))

(defun inline-crypt--make-decrypted-keymap ()
  "Keymap for temporarily decrypted blocks."
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c r") #'inline-crypt-relock-at-point)
    map))

;;; ── Collapse / expand helpers ───────────────────────────────

(defvar-local inline-crypt--overlays nil
  "List of overlays used to display collapsed encrypted blocks.")

(defvar-local inline-crypt--protect-overlays nil
  "Overlays that block edits to visible ciphertext regions.")

(defconst inline-crypt--pgp-begin "-----BEGIN PGP MESSAGE-----"
  "Literal start marker for inline PGP armor blocks.")

(defconst inline-crypt--pgp-end "-----END PGP MESSAGE-----"
  "Literal end marker for inline PGP armor blocks.")

(defun inline-crypt--deny-insert (_ov _before-p)
  "Hook that prevents inserting into a protected ciphertext region."
  (user-error "Cannot modify encrypted ciphertext"))

(defun inline-crypt--clear-protect-overlays (&optional beg end)
  "Remove ciphertext protection overlays, optionally limited to BEG..END."
  (setq inline-crypt--protect-overlays
        (delq nil
              (mapcar
               (lambda (ov)
                 (if (not (overlay-buffer ov))
                     nil
                   (if (and beg end
                            (not (and (>= (overlay-end ov) beg)
                                      (<= (overlay-start ov) end))))
                       ov
                     (progn (delete-overlay ov) nil))))
               inline-crypt--protect-overlays))))

(defun inline-crypt--protect-overlay-at (beg end)
  "Return the existing protect overlay for BEG..END, or nil."
  (catch 'found
    (dolist (ov (overlays-in beg end))
      (when (and (overlay-get ov 'inline-crypt-protect)
                 (= (overlay-start ov) beg)
                 (= (overlay-end ov) end))
        (throw 'found ov)))
    nil))

(defun inline-crypt--protect-armor-region (beg end)
  "Make ciphertext BEG..END read-only using text properties and overlays."
  (unless (inline-crypt--protect-overlay-at beg end)
    (inline-crypt--clear-protect-overlays beg end)
    (let ((keymap (inline-crypt--make-collapsed-keymap)))
      (with-silent-modifications
        (add-text-properties beg end
                             `(read-only t
                               front-sticky t
                               rear-nonsticky t
                               face inline-crypt-encrypted-face
                               keymap ,keymap
                               help-echo "Ciphertext (read-only) — C-c v hide, C-c d decrypt")))
      (let ((ov (make-overlay beg end nil t nil)))
        (overlay-put ov 'inline-crypt-protect t)
        (overlay-put ov 'evaporate t)
        (overlay-put ov 'insert-in-front-hooks (list #'inline-crypt--deny-insert))
        (overlay-put ov 'insert-behind-hooks (list #'inline-crypt--deny-insert))
        (overlay-put ov 'keymap keymap)
        (push ov inline-crypt--protect-overlays)))))

(defun inline-crypt--property-region-at-point (prop)
  "Return (beg . end) of text with property PROP at point, or nil."
  (let ((pos (point)))
    (unless (get-text-property pos prop)
      (cond
       ((and (< pos (point-max)) (get-text-property (1+ pos) prop))
        (setq pos (1+ pos)))
       ((and (> pos (point-min)) (get-text-property (1- pos) prop))
        (setq pos (1- pos)))
       (t (setq pos nil))))
    (when (and pos (get-text-property pos prop))
      (let ((beg (previous-single-property-change (1+ pos) prop))
            (end (next-single-property-change pos prop)))
        (cons (or beg (point-min)) (or end (point-max)))))))

(defun inline-crypt--collapsed-at-point ()
  "Return (beg . end) of the collapsed indicator at point, or nil."
  (inline-crypt--property-region-at-point 'inline-crypt-collapsed))

(defun inline-crypt--decrypted-at-point ()
  "Return (beg . end) of the decrypted plaintext block at point, or nil."
  (inline-crypt--property-region-at-point 'inline-crypt-decrypted))

(defun inline-crypt--armor-visible-at-point ()
  "Return (beg . end) of expanded-but-not-decrypted block at point, or nil."
  (and (not (inline-crypt--collapsed-at-point))
       (let ((bounds (inline-crypt--find-block-bounds)))
         (when (and bounds (not (get-text-property (car bounds) 'inline-crypt-decrypted)))
           bounds))))

(defun inline-crypt--expand-block (beg end)
  "Remove the overlay and text properties at BEG..END to reveal the underlying PGP block.
The revealed ciphertext is read-only.  Returns (new-beg . new-end), or nil on failure."
  (when (get-text-property beg 'inline-crypt-collapsed)
    (dolist (ov (overlays-in beg end))
      (when (overlay-get ov 'inline-crypt-overlay)
        (delete-overlay ov)))
    (with-silent-modifications
      (remove-text-properties beg end
                              '(inline-crypt-collapsed nil read-only nil
                                front-sticky nil rear-nonsticky nil
                                keymap nil help-echo nil))
      (add-text-properties beg end '(inline-crypt-hidden t)))
    (inline-crypt--protect-armor-region beg end)
    (cons beg end)))

(defun inline-crypt--collapse-block (beg end)
  "Hide the encrypted block at BEG..END behind a lock indicator.
Uses an overlay with `display' property so the underlying ciphertext remains in the buffer.
This is non-destructive: the original text is preserved for saving.
The overlay approach avoids conflicts with font-lock."
  (when inline-crypt-collapse-encrypted
    (inline-crypt--clear-protect-overlays beg end)
    (let ((keymap (inline-crypt--make-collapsed-keymap)))
      (let ((ov (make-overlay beg end nil t nil)))
        (overlay-put ov 'display inline-crypt-collapsed-indicator)
        (overlay-put ov 'face (if (facep 'inline-crypt-collapsed-face)
                                  'inline-crypt-collapsed-face
                                'warning))
        (overlay-put ov 'inline-crypt-overlay t)
        (overlay-put ov 'evaporate t)
        (overlay-put ov 'keymap keymap)
        (overlay-put ov 'help-echo "Encrypted — C-c d decrypt, C-c v view ciphertext")
        (push ov inline-crypt--overlays))
      (with-silent-modifications
        (add-text-properties
         beg end
         `(inline-crypt-collapsed t
           inline-crypt-hidden t
           read-only t
           keymap ,keymap
           help-echo "Encrypted — C-c d decrypt, C-c v view ciphertext"))))))

(defun inline-crypt--restore-armor (beg end armor)
  "Replace region BEG..END with ARMOR and collapse to the lock indicator."
  (let ((inhibit-read-only t))
    (delete-region beg end)
    (let ((ins-pos (point)))
      (insert armor)
      (with-silent-modifications
        (add-text-properties ins-pos (point)
                             '(face inline-crypt-encrypted-face)))
      (inline-crypt--collapse-block ins-pos (point)))))

;;; ── Scan and collapse existing blocks ────────────────────────

(defvar-local inline-crypt--collapsing nil
  "Non-nil while `inline-crypt--collapse-all-in-buffer' is running.")

(defvar-local inline-crypt--collapse-timer nil
  "Idle timer for debounced collapse; prevents hook feedback loops.")

(defun inline-crypt--block-already-collapsed-p (beg)
  "Return non-nil if the PGP block starting near BEG is already collapsed."
  (or (get-text-property beg 'inline-crypt-collapsed)
      (catch 'found
        (dolist (ov (overlays-in beg (min (point-max) (+ beg 512))))
          (when (overlay-get ov 'inline-crypt-overlay)
            (throw 'found t)))
        nil)))

(defun inline-crypt--collapse-all-in-buffer ()
  "Find plain PGP blocks that still need collapsing and fold them to 🔐."
  (interactive)
  (when (and inline-crypt-collapse-encrypted (not inline-crypt--collapsing))
    (let ((inline-crypt--collapsing t)
          (count 0))
      (save-excursion
        (goto-char (point-min))
        (while (re-search-forward (regexp-quote inline-crypt--pgp-begin) nil t)
          (let ((hit (match-beginning 0)))
            (unless (get-text-property hit 'inline-crypt-decrypted)
              (goto-char hit)
              (let ((block (inline-crypt--find-block-bounds)))
                (when block
                  (let ((bbeg (car block))
                        (bend (cdr block)))
                    (cond
                     ((get-text-property bbeg 'inline-crypt-user-expanded)
                      (inline-crypt--protect-armor-region bbeg bend))
                     ((inline-crypt--block-already-collapsed-p bbeg)
                      nil)
                     (t
                      (inline-crypt--collapse-block bbeg bend)
                      (setq count (1+ count)))))))))))
      (when (> count 0)
        (message "Collapsed %d encrypted block(s)." count)))))

(defun inline-crypt--schedule-collapse (&optional delay)
  "Debounced wrapper around `inline-crypt--collapse-all-in-buffer'."
  (let ((buf (current-buffer)))
    (when inline-crypt--collapse-timer
      (cancel-timer inline-crypt--collapse-timer))
    (setq inline-crypt--collapse-timer
          (run-with-idle-timer (or delay 0.2) nil
                               (lambda ()
                                 (setq inline-crypt--collapse-timer nil)
                                 (when (buffer-live-p buf)
                                   (with-current-buffer buf
                                     (inline-crypt--collapse-all-in-buffer))))))))

;;; ── Find encrypted block at point ──────────────────────────

(defun inline-crypt--find-block-bounds ()
  "Return (beg . end) of the encrypted block at point, or nil."
  (save-excursion
    (let ((orig (point))
          beg end)
      (cond
       ((looking-at inline-crypt--pgp-begin)
        (setq beg (match-beginning 0)))
       ((re-search-backward (regexp-quote inline-crypt--pgp-begin) nil t)
        (setq beg (match-beginning 0)))
       (t nil))
      (when beg
        (let ((delim-beg (save-excursion
                           (goto-char beg)
                           (inline-crypt--opening-delimiter-at-point))))
          (when delim-beg
            (setq beg delim-beg)))
        (goto-char beg)
        (when (re-search-forward (regexp-quote inline-crypt--pgp-end) nil t)
          (setq end (inline-crypt--extend-end-for-closing-delimiter (match-end 0)))
          (when (and (<= beg orig) (<= orig end))
            (cons beg end)))))))

;;; ── Track decrypted blocks for re-encryption on save ───────

(defvar-local inline-crypt--decrypted-blocks nil
  "Alist of ((beg . end) plaintext . original-armor) for blocks decrypted in this buffer.")

(defun inline-crypt--register-decrypted (beg end plaintext original-armor)
  "Register a decrypted block so it can be re-encrypted before save.
ORIGINAL-ARMOR is the original ciphertext; if the plaintext is not modified,
this exact armor is restored instead of re-encrypting."
  (push (list (cons beg end) plaintext original-armor) inline-crypt--decrypted-blocks))

(defun inline-crypt--find-decrypted-entry (beg)
  "Return the decrypted-block entry whose region starts at BEG, or nil."
  (catch 'found
    (dolist (entry inline-crypt--decrypted-blocks)
      (when (= beg (car (car entry)))
        (throw 'found entry)))
    nil))

(defun inline-crypt--current-decrypted-end (beg fallback-end)
  "Return the current end position of a decrypted block starting at BEG."
  (if (get-text-property beg 'inline-crypt-decrypted)
      (or (next-single-property-change beg 'inline-crypt-decrypted)
          (point-max))
    fallback-end))

(defun inline-crypt--sort-decrypted-entries-by-position (entries)
  "Return ENTRIES sorted by decreasing start position (process end-first)."
  (sort (copy-sequence entries)
        (lambda (a b)
          (> (car (car a)) (car (car b))))))

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
         (plaintext-bytes (encode-coding-string plaintext 'utf-8))
         (context (epg-make-context 'OpenPGP))
         (keys (ignore-errors (epg-list-keys context inline-crypt-gpg-key)))
         (encrypted (epg-encrypt-string context plaintext-bytes
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
    (let ((block (inline-crypt--find-block-bounds)))
      (when block
        (with-silent-modifications
          (add-text-properties (car block) (cdr block)
                               '(face inline-crypt-encrypted-face)))
        (inline-crypt--collapse-block (car block) (cdr block))))
    (message "Text encrypted (%d chars → %d chars). %s to decrypt."
             (length plaintext) (length encrypted)
             (if inline-crypt-collapse-encrypted
                 "C-c d on 🔐"
               "C-c d"))))

;;; ── Toggle ciphertext visibility ───────────────────────────

;;;###autoload
(defun inline-crypt-toggle-armor-visibility ()
  "Toggle encrypted block between lock indicator and visible ciphertext.
Does not decrypt — only changes display."
  (interactive)
  (cond
   ((inline-crypt--collapsed-at-point)
    (let* ((collapsed (inline-crypt--collapsed-at-point))
           (beg (car collapsed))
           (end (cdr collapsed)))
      (inline-crypt--expand-block beg end)
      (with-silent-modifications
        (add-text-properties beg end '(inline-crypt-user-expanded t)))
      (goto-char beg)
      (message "Showing ciphertext (read-only). C-c v to hide, C-c d to decrypt.")))
   ((inline-crypt--armor-visible-at-point)
    (let* ((bounds (inline-crypt--armor-visible-at-point))
           (beg (car bounds))
           (end (cdr bounds)))
      (with-silent-modifications
        (remove-text-properties beg end
                                '(inline-crypt-user-expanded nil
                                  inline-crypt-hidden nil
                                  read-only nil
                                  front-sticky nil
                                  rear-nonsticky nil
                                  keymap nil
                                  help-echo nil
                                  face nil)))
      (inline-crypt--clear-protect-overlays beg end)
      (inline-crypt--collapse-block beg end)
      (message "Hidden ciphertext behind lock indicator.")))
   (t
    (user-error "No encrypted block at point"))))

;;; ── Decrypt block at point ─────────────────────────────────

;;;###autoload
(defun inline-crypt-decrypt-at-point ()
  "Decrypt the encrypted block at point, replacing it with plaintext.
If point is on a collapsed 🔐 indicator, expand it first before decrypting.
The plaintext is tracked so it can be re-encrypted before saving."
  (interactive)
  (unless (executable-find "gpg")
    (user-error "GPG not found.  Install with: brew install gnupg"))
  (let ((collapsed (inline-crypt--collapsed-at-point)))
    (when collapsed
      (let ((expanded (inline-crypt--expand-block (car collapsed) (cdr collapsed))))
        (unless expanded
          (user-error "Failed to expand collapsed block"))
        (goto-char (cdr expanded)))))
  (let* ((bounds (inline-crypt--find-block-bounds))
         (beg (car bounds))
         (end (cdr bounds)))
    (unless bounds
      (user-error "No encrypted block found at point"))
    (let* ((armor (buffer-substring-no-properties beg end))
           (context (epg-make-context 'OpenPGP))
           (raw-plaintext
            (condition-case err
                (epg-decrypt-string context armor)
              (error
               (user-error "Decryption failed: %s"
                           (error-message-string err)))))
           (plaintext (decode-coding-string raw-plaintext 'utf-8))
           (keymap (inline-crypt--make-decrypted-keymap)))
      (let ((inhibit-read-only t))
        (delete-region beg end)
        (insert plaintext))
      (let ((ins-pos beg))
        (inline-crypt--clear-protect-overlays beg end)
        (inline-crypt--register-decrypted ins-pos (point) plaintext armor)
        (with-silent-modifications
          (add-text-properties ins-pos (point)
                               `(face inline-crypt-decrypted-face
                                 inline-crypt-decrypted t
                                 keymap ,keymap
                                 help-echo "Decrypted — C-c r to relock if unchanged")))
        (set-buffer-modified-p nil)
        (message "Text decrypted (%d chars). C-c r to relock, or save to re-encrypt."
                 (length plaintext))
        (goto-char ins-pos)))))

;;; ── Relock unchanged decrypted block ───────────────────────

;;;###autoload
(defun inline-crypt-relock-at-point ()
  "If decrypted block at point is unchanged, restore ciphertext and collapse to 🔐.
Does not write to disk — the buffer stays unmodified."
  (interactive)
  (let* ((region (inline-crypt--decrypted-at-point))
         (beg (car region))
         (end (cdr region)))
    (unless region
      (user-error "No decrypted block at point"))
    (let ((entry (inline-crypt--find-decrypted-entry beg)))
      (unless entry
        (user-error "No tracked decrypted block at point"))
      (let ((current-text (buffer-substring-no-properties beg end))
            (old-plaintext (cadr entry))
            (original-armor (caddr entry)))
        (if (string= current-text old-plaintext)
            (progn
              (inline-crypt--restore-armor beg end original-armor)
              (setq inline-crypt--decrypted-blocks
                    (delq entry inline-crypt--decrypted-blocks))
              (set-buffer-modified-p nil)
              (message "Relocked (content unchanged, buffer not saved)."))
          (user-error "Decrypted text was modified — save to re-encrypt, or undo edits first"))))))

;;; ── Auto re-encrypt on save ────────────────────────────────

(defun inline-crypt--reencrypt-before-save ()
  "Re-encrypt any decrypted blocks before saving the buffer.
If a block's plaintext was not modified, restore the original armor
instead of re-encrypting to avoid unnecessary file changes."
  (when inline-crypt--decrypted-blocks
    (let ((re-encrypted 0)
          (restored 0))
      (dolist (entry (inline-crypt--sort-decrypted-entries-by-position
                      inline-crypt--decrypted-blocks))
        (let* ((bounds (car entry))
               (old-plaintext (cadr entry))
               (original-armor (caddr entry))
               (beg (car bounds))
               (stored-end (cdr bounds))
               (end (inline-crypt--current-decrypted-end beg stored-end)))
          (when (and (>= beg 0) (<= beg end) (<= end (point-max)))
            (let ((current-text (buffer-substring-no-properties beg end)))
              (when (and current-text (> (length current-text) 0))
                (if (string= current-text old-plaintext)
                    (progn
                      (inline-crypt--restore-armor beg end original-armor)
                      (setq restored (1+ restored)))
                  (let* ((context (epg-make-context 'OpenPGP))
                         (keys (ignore-errors
                                 (epg-list-keys context inline-crypt-gpg-key)))
                         (text-bytes (encode-coding-string current-text 'utf-8))
                         (encrypted (epg-encrypt-string
                                     context text-bytes
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
                        (let ((new-block (inline-crypt--find-block-bounds)))
                          (when new-block
                            (with-silent-modifications
                              (add-text-properties
                               (car new-block) (cdr new-block)
                               '(face inline-crypt-encrypted-face)))
                            (inline-crypt--collapse-block (car new-block) (cdr new-block))))
                        (setq re-encrypted (1+ re-encrypted))))))))))
      (setq inline-crypt--decrypted-blocks nil)
      (cond
       ((and (> restored 0) (> re-encrypted 0))
        (message "Saved %d unchanged block(s), re-encrypted %d modified block(s)."
                 restored re-encrypted))
       ((> restored 0)
        (message "Restored %d unchanged block(s) (no re-encryption needed)."
                 restored))
       ((> re-encrypted 0)
        (message "Re-encrypted %d modified block(s) before save." re-encrypted)))))))

;;; ── Minor mode ─────────────────────────────────────────────

;;;###autoload
(define-minor-mode inline-crypt-mode
  "Toggle inline text encryption capability.
When enabled:
  \\[inline-crypt-encrypt-region] - encrypt selected region
  \\[inline-crypt-toggle-armor-visibility] - toggle lock indicator / ciphertext
  \\[inline-crypt-decrypt-at-point] - decrypt block at point
  \\[inline-crypt-relock-at-point] - relock unchanged decrypted block

Encrypted blocks are re-encrypted automatically when saving the buffer."
  :lighter " 🔒"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c e") #'inline-crypt-encrypt-region)
            (define-key map (kbd "C-c v") #'inline-crypt-toggle-armor-visibility)
            (define-key map (kbd "C-c d") #'inline-crypt-decrypt-at-point)
            (define-key map (kbd "C-c r") #'inline-crypt-relock-at-point)
            map)
  (if inline-crypt-mode
      (progn
        (add-hook 'before-save-hook #'inline-crypt--reencrypt-before-save nil t)
        (inline-crypt--schedule-collapse 0.1))
    (progn
      (when inline-crypt--collapse-timer
        (cancel-timer inline-crypt--collapse-timer)
        (setq inline-crypt--collapse-timer nil))
      (dolist (ov inline-crypt--overlays)
        (when (overlay-buffer ov)
          (delete-overlay ov)))
      (setq inline-crypt--overlays nil)
      (inline-crypt--clear-protect-overlays)
      (remove-hook 'before-save-hook #'inline-crypt--reencrypt-before-save t)))
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
    t))

;;; ── Enable in relevant modes by default ────────────────────
;; Use (inline-crypt-mode 1) to enable explicitly — never toggle from hooks.
(defun inline-crypt--turn-on ()
  (inline-crypt-mode 1))

(add-hook 'org-mode-hook #'inline-crypt--turn-on)
(add-hook 'markdown-mode-hook #'inline-crypt--turn-on)
(add-hook 'text-mode-hook #'inline-crypt--turn-on)

(provide 'setup-inline-crypt)
