(require 'json)

(let ((location "via") (message "fn") (hypothesis-id "F") (data '((:x 1))))
  (condition-case err
      (insert
       (concat
        (json-encode `((sessionId . "c9fe51")
                       (hypothesisId . ,hypothesis-id)
                       (location . ,location)
                       (message . ,message)
                       (data . ,(let ((print-length nil) (print-level nil)) data))
                       (timestamp . ,(floor (* 1000 (float-time)))))
        "\n"))
    (error (message "encode ERR: %s" (error-message-string err)))))

(message "buf=%S" (buffer-string))
