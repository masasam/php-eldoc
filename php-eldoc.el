(load (concat (directory-file-name
               (file-name-directory (or load-file-name
                                        (buffer-file-name))))
              "/php-standard-functions.el"))

;; (defvar remote-ran nil)
;; (make-variable-buffer-local 'remote-ran)


(defvar php-eldoc-functions-hash
  (let ((hash (make-hash-table :size 2500 :test 'equal)))
    (dolist (func php-standard-functions)
      (puthash (car func) (rest func) hash))
    hash))

(defun php-eldoc-function ()
  (let* ((func (sc-function-and-argument))
         (hash-result (when func (gethash (car func) php-eldoc-functions-hash)))
         (arguments "")
         (counter 0))
    (when hash-result
      (dolist (arg hash-result)
        (setq arguments (concat arguments
                                (if (equal counter (second func))
                                    (propertize arg 'face '(:weight bold))
                                    arg)
                                ", "))
        (incf counter)))
    (when (>= (length arguments) 2)
      (setq arguments (substring arguments 0 (- (length arguments) 2))))
    (when hash-result
      (concat (propertize (first func) 'face 'font-lock-function-name-face)
              "( " arguments " )")
      )))

(defvar php-remote-functions nil)

(defun php-eldoc-probe-callback (orignial-buffer)
  (goto-char (point-min))
  (search-forward "(set")
  (goto-char (match-beginning 0))
  (delete-region (point-min) (point))
  (eval-buffer)
  (es-kill-buffer-dont-ask)
  (set-buffer orignial-buffer)
  (set ;; php-eldoc-functions-hash
   (make-local-variable 'php-eldoc-functions-hash)
   (let ((hash (make-hash-table :size 2500 :test 'equal)))
     (dolist (func php-remote-functions)
       (puthash (car func) (rest func) hash))
     hash))
  ;; (message "remote eldoc")
  )

(defun php-eldoc-probe-load (url)
  (url-retrieve
   url (eval `(lambda (&rest ignore)
                (php-eldoc-probe-callback
                 ,(current-buffer))))))

(defun php-eldoc-ac-candidates ()
  ;; (mapcar
  ;;  (lambda (thing)
  ;;    (concat thing "_thing"))
  ;;  (list "ab" "ac" "ad"))
  (let (result)
    (maphash (lambda (key value)
               (push key result))
             php-eldoc-functions-hash)
    result))

(eval-after-load 'auto-complete
  '(ac-define-source php-eldoc
    '((candidates . php-eldoc-ac-candidates)
      ;; (available . ac-emacs-eclim-available)
      ;; (init . ac-emacs-eclim-init)
      ;; (action . ac-emacs-eclim-action)
      ;; (requires . 0)
      (cache)
      ;; (selection-face . ac-emacs-eclim-selection-face)
      ;; (candidate-face . ac-emacs-eclim-candidate-face)
      (symbol . "f"))))

(defun php-eldoc-enable ()
  (interactive)
  (when (and (fboundp 'auto-complete-mode)
             auto-complete-mode)
    (pushnew 'ac-source-php-eldoc ac-sources))
  (set (make-local-variable 'eldoc-documentation-function)
       'php-eldoc-function)
  (eldoc-mode 1))

(provide 'php-eldoc)