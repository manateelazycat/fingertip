;;; fingertip.el --- Fingertip is struct edit plugin that base on treesit   -*- lexical-binding: t; -*-

;; Filename: fingertip.el
;; Description: Fingertip is struct edit plugin that base on treesit
;; Author: Andy Stewart <lazycat.manatee@gmail.com>
;; Maintainer: Andy Stewart <lazycat.manatee@gmail.com>
;; Copyright (C) 2023, Andy Stewart, all rights reserved.
;; Created: 2023-02-04 14:04:10
;; Version: 0.1
;; Last-Updated: 2023-02-04 14:04:10
;;           By: Andy Stewart
;; URL: https://www.github.com/manateelazycat/fingertip
;; Keywords:
;; Compatibility: GNU Emacs 30.0.50
;;
;; Features that might be required by this library:
;;
;;
;;

;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Fingertip is struct edit plugin that base on treesit
;;

;;; Installation:
;;
;; Put fingertip.el to your load-path.
;; The load-path is usually ~/elisp/.
;; It's set in your ~/.emacs like this:
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;;
;; And the following to your ~/.emacs startup file.
;;
;; (require 'fingertip)
;;
;; No need more.

;;; Customize:
;;
;;
;;
;; All of the above can customize by:
;;      M-x customize-group RET fingertip RET
;;

;;; Change log:
;;
;; 2023/02/04
;;      * First released.
;;

;;; Acknowledgements:
;;
;;
;;

;;; TODO
;;
;;
;;

;;; Require
(require 'subr-x)
(require 'thingatpt)
(require 'treesit)

;;; Code:

(defgroup fingertip nil
  "Edit grammatically."
  :group 'fingertip)

(defvar fingertip-mode-map (make-sparse-keymap)
  "Keymap for the fingertip minor mode.")

;;;###autoload
(define-minor-mode fingertip-mode
  "Minor mode for auto parenthesis pairing with syntax table.
\\<fingertip-mode-map>"
  :group 'fingertip)

(defmacro fingertip-ignore-errors (body)
  `(ignore-errors
     ,body
     t))

(defcustom fingertip-save-in-kill-ring t
  "Whether save kill thing into kill-ring."
  :type 'boolean
  :group 'fingertip)

;;;;;;;;;;;;;;;;; Interactive functions ;;;;;;;;;;;;;;;;;;;;;;

(defun fingertip-delete-region (beg end)
  (if fingertip-save-in-kill-ring
      (kill-region beg end)
    (delete-region beg end)))

(defun fingertip-open-object (object-start object-end)
  (interactive)
  (cond
   ((region-active-p)
    (fingertip-wrap-round))
   ((and (fingertip-in-string-p)
         (derived-mode-p 'js-mode))
    (insert (format "%s%s" object-start object-end))
    (backward-char))
   ((or (fingertip-in-string-p)
        (fingertip-in-comment-p))
    (insert object-start))
   (t
    (insert (format "%s%s" object-start object-end))
    (backward-char))))

(defun fingertip-open-round ()
  (interactive)
  (fingertip-open-object "(" ")"))

(defun fingertip-open-curly ()
  (interactive)
  (fingertip-open-object "{" "}"))

(defun fingertip-open-bracket ()
  (interactive)
  (fingertip-open-object "[" "]"))

(defun fingertip-open-chinese-round ()
  (interactive)
  (fingertip-open-object "（" "）"))

(defun fingertip-open-chinese-curly ()
  (interactive)
  (fingertip-open-object "【" "】"))

(defun fingertip-open-chinese-bracket ()
  (interactive)
  (fingertip-open-object "「" "」"))

(defun fingertip-fix-unbalanced-parentheses ()
  (interactive)
  (let ((close (fingertip-missing-close)))
    (if close
        (cond ((eq ?\) (matching-paren close))
               (insert ")"))
              ((eq ?\} (matching-paren close))
               (insert "}"))
              ((eq ?\] (matching-paren close))
               (insert "]"))
              ((eq ?\） (matching-paren close))
               (insert "）"))
              ((eq ?\】 (matching-paren close))
               (insert "】"))
              ((eq ?\」 (matching-paren close))
               (insert "」")))
      (up-list))))

(defun fingertip-close-round ()
  (interactive)
  (cond ((or (fingertip-in-string-p)
             (fingertip-in-comment-p))
         (insert ")"))
        ;; Insert ) directly in sh-mode for case ... in syntax.
        ((or
          (derived-mode-p 'sh-mode)
          (derived-mode-p 'markdown-mode))
         (insert ")"))
        (t
         (fingertip-fix-unbalanced-parentheses))))

(defun fingertip-close-curly ()
  (interactive)
  (cond ((or (fingertip-in-string-p)
             (fingertip-in-comment-p))
         (insert "}"))
        (t
         (fingertip-fix-unbalanced-parentheses))))

(defun fingertip-close-bracket ()
  (interactive)
  (cond ((or (fingertip-in-string-p)
             (fingertip-in-comment-p))
         (insert "]"))
        (t
         (fingertip-fix-unbalanced-parentheses))))

(defun fingertip-close-chinese-round ()
  (interactive)
  (cond ((or (fingertip-in-string-p)
             (fingertip-in-comment-p))
         (insert "）"))
        ;; Insert ) directly in sh-mode for case ... in syntax.
        ((or
          (derived-mode-p 'sh-mode)
          (derived-mode-p 'markdown-mode))
         (insert "）"))
        (t
         (fingertip-fix-unbalanced-parentheses))))

(defun fingertip-close-chinese-curly ()
  (interactive)
  (cond ((or (fingertip-in-string-p)
             (fingertip-in-comment-p))
         (insert "】"))
        (t
         (fingertip-fix-unbalanced-parentheses))))

(defun fingertip-close-chinese-bracket ()
  (interactive)
  (cond ((or (fingertip-in-string-p)
             (fingertip-in-comment-p))
         (insert "」"))
        (t
         (fingertip-fix-unbalanced-parentheses))))

(defun fingertip-single-quote ()
  (interactive)
  (cond ((or (fingertip-is-lisp-mode-p)
             (derived-mode-p 'markdown-mode)
             (derived-mode-p 'rust-mode)
             (derived-mode-p 'rust-ts-mode)
             (fingertip-in-comment-p)
             (and (boundp 'acm-enable-search-sdcv-words)
                  acm-enable-search-sdcv-words))
         (insert "'"))
        ((region-active-p)
         (fingertip-wrap-single-quote))
        ((or (derived-mode-p 'python-mode)
             (derived-mode-p 'python-ts-mode))
         (if (string-equal (fingertip-get-non-space-string-before-point) "''")
             ;; Become '''''' if string before cursor is ''.
             (progn
               (insert "''''")
               (backward-char 3))
           ;; Otherwise insert ''.
           (insert "''")
           (backward-char)))
        ((fingertip-in-string-p)
         (insert "'"))
        (t
         (insert "''")
         (backward-char))))

(defun fingertip-get-non-space-string-before-point ()
  (interactive)
  (save-excursion
    (let (start end)
      (skip-chars-backward " \t")
      (setq end (point))
      (skip-chars-backward "^ \t\n")
      (setq start (point))
      (if (< start end)
          (buffer-substring-no-properties start end)
        nil))))

(defun fingertip-double-quote ()
  (interactive)
  (cond ((region-active-p)
         (fingertip-wrap-double-quote))
        ((fingertip-in-single-quote-string-p)
         (insert "\""))
        ((fingertip-in-string-p)
         (cond
          ((and (derived-mode-p 'python-mode)
                (and (eq (char-before) ?\") (eq (char-after) ?\")))
           (insert "\"\"")
           (backward-char))
          ;; When current mode is golang.
          ;; Don't insert \" in string that wrap by `...`
          ((and (derived-mode-p 'go-mode)
                (equal (save-excursion (nth 3 (fingertip-current-parse-state))) 96))
           (insert "\""))
          (t
           (insert "\\\""))))
        ((fingertip-in-comment-p)
         (insert "\""))
        (t
         (insert "\"\"")
         (backward-char))))

(defun fingertip-space (arg)
  "Wrap space around cursor if cursor in blank parenthesis.

input: {|} (press <SPACE> at |)
output: { | }

input: [|] (press <SPACE> at |)
output: [ | ]
"
  (interactive "p")
  (if (> arg 1)
      (self-insert-command arg)
    (cond ((or (fingertip-in-comment-p)
               (fingertip-in-string-p))
           (insert " "))
          ((or (and (equal (char-after) ?\} )
                    (equal (char-before) ?\{ ))
               (and (equal (char-after) ?\] )
                    (equal (char-before) ?\[ )))
           (insert "  ")
           (backward-char 1))
          (t
           ;; Add `ignore-errors' avoid failed on ielm.
           (ignore-errors (insert " "))))))

(defun fingertip-web-mode-match-paren ()
  (require 'sgml-mode)
  (cond ((looking-at "<")
         (sgml-skip-tag-forward 1))
        ((looking-back ">" nil)
         (sgml-skip-tag-backward 1))
        (t (self-insert-command 1))))

(defun fingertip-backward-delete ()
  (interactive)
  (cond ((fingertip-in-string-p)
         (fingertip-backward-delete-in-string))
        ((fingertip-in-comment-p)
         (backward-delete-char 1))
        ((fingertip-after-close-pair-p)
         (if (and (derived-mode-p 'sh-mode)
                  (eq ?\) (char-before)))
             (delete-char -1)
           (backward-char)))
        ((fingertip-in-empty-pair-p)
         (fingertip-backward-delete-in-pair))
        ((not (fingertip-after-open-pair-p))
         (backward-delete-char 1))))

(defun fingertip-forward-delete ()
  (interactive)
  (cond ((region-active-p)
         (fingertip-delete-region (region-beginning) (region-end)))
        ((fingertip-in-empty-backquote-string-p)
         (fingertip-delete-empty-backquote-string))
        ((fingertip-in-empty-string-p)
         (fingertip-delete-empty-string))
        ((fingertip-in-string-p)
         (fingertip-forward-delete-in-string))
        ((fingertip-in-comment-p)
         (delete-char 1))
        ((fingertip-before-string-open-quote-p)
         (fingertip-forward-movein-string))
        ((fingertip-before-open-pair-p)
         (forward-char))
        ((fingertip-in-empty-pair-p)
         (fingertip-backward-delete-in-pair))
        ((and (derived-mode-p 'sh-mode)
              (fingertip-before-close-pair-p)
              (eq ?\) (char-after)))
         (delete-char 1))
        ((not (fingertip-before-close-pair-p))
         (delete-char 1))))

(defun fingertip-kill ()
  "Intelligent soft kill.

When inside of code, kill forward S-expressions on the line, but
respecting delimeters.
When in a string, kill to the end of the string.
When in comment, kill to the end of the line."
  (interactive)
  (cond ((region-active-p)
         (fingertip-delete-region (region-beginning) (region-end)))
        ((derived-mode-p 'web-mode)
         (fingertip-web-mode-kill))
        (t
         (fingertip-common-mode-kill))))

(defun fingertip-backward-kill ()
  "Intelligent soft kill.

When inside of code, kill backward S-expressions on the line, but
respecting delimiters.
When in a string, kill to the beginning of the string.
When in comment, kill to the beginning of the line."
  (interactive)
  (cond ((derived-mode-p 'web-mode)
         (fingertip-web-mode-backward-kill))
        (t
         (fingertip-common-mode-backward-kill))))

(defun fingertip-wrap-double-quote ()
  (interactive)
  (cond ((and (region-active-p)
              (fingertip-in-string-p))
         (cond ((and (derived-mode-p 'go-mode)
                     (equal (save-excursion (nth 3 (fingertip-current-parse-state))) 96))
                (fingertip-wrap-region "\"" "\""))
               (t
                (fingertip-wrap-region "\\\"" "\\\""))))
        ((region-active-p)
         (fingertip-wrap-region "\"" "\""))
        ((fingertip-in-string-p)
         (goto-char (cdr (fingertip-current-node-range))))
        ((fingertip-in-comment-p)
         (fingertip-wrap (beginning-of-thing 'symbol) (end-of-thing 'symbol) "\"" "\""))
        ((fingertip-is-lisp-mode-p)
         (fingertip-wrap (beginning-of-thing 'sexp) (end-of-thing 'sexp) "\"" "\""))
        (t
         (fingertip-wrap (beginning-of-thing 'symbol) (end-of-thing 'symbol) "\"" "\""))))

(defun fingertip-wrap-single-quote ()
  (interactive)
  (cond ((region-active-p)
         (fingertip-wrap-region "'" "'"))
        ((fingertip-in-comment-p)
         (fingertip-wrap (beginning-of-thing 'symbol) (end-of-thing 'symbol) "'" "'"))
        ((fingertip-is-lisp-mode-p)
         (fingertip-wrap (beginning-of-thing 'sexp) (end-of-thing 'sexp) "'" "'"))
        (t
         (fingertip-wrap (beginning-of-thing 'symbol) (end-of-thing 'symbol) "'" "'"))))

(defun fingertip-wrap-round ()
  (interactive)
  (cond
   ;; If in *.Vue file
   ;; In template area, call `fingertip-web-mode-element-wrap'
   ;; Otherwise, call `fingertip-wrap-round-pair'
   ((and (buffer-file-name) (string-equal (file-name-extension (buffer-file-name)) "vue"))
    (if (fingertip-vue-in-template-area-p)
        (fingertip-web-mode-element-wrap)
      (fingertip-wrap-round-pair)))
   ;; If is `web-mode' but not in *.Vue file, call `fingertip-web-mode-element-wrap'
   ((derived-mode-p 'web-mode)
    (if (fingertip-in-script-area-p)
        (fingertip-wrap-round-pair)
      (fingertip-web-mode-element-wrap)))
   ;; Otherwise call `fingertip-wrap-round-pair'
   (t
    (fingertip-wrap-round-pair))))

(defun fingertip-wrap-round-object (object-start object-end)
  (let* ((not-between-in-round (and (fingertip-is-lisp-mode-p)
                                    (equal (char-before) ?\()
                                    (not (equal (char-after) ?\()))))
    (cond ((region-active-p)
           (fingertip-wrap-region object-start object-end))
          ((fingertip-in-comment-p)
           (fingertip-wrap (beginning-of-thing 'symbol) (end-of-thing 'symbol) object-start object-end))
          ((fingertip-is-lisp-mode-p)
           (fingertip-wrap (beginning-of-thing 'sexp) (end-of-thing 'sexp) object-start object-end))
          ((member (fingertip-node-type-at-point) (list "{" "(" "["))
           (let ((match-paren-pos (save-excursion
                                    (fingertip-match-paren 1)
                                    (point))))
             (fingertip-wrap (point) match-paren-pos object-start object-end)))
          (t
           (when (fingertip-before-string-open-quote-p)
             (fingertip-forward-movein-string))
           (let ((string-bound (fingertip-current-node-range)))
             (fingertip-wrap (car string-bound) (cdr string-bound) object-start object-end))))

    (unless (or (fingertip-in-string-p)
                (fingertip-in-comment-p))
      ;; Indent wrap area.
      (fingertip-indent-parent-area)

      ;; Backward char if cursor in nested roud, such as `( ... )|)`
      (when (fingertip-nested-round-p)
        (backward-char 1))

      ;; Jump to start position of parent node.
      (unless (fingertip-is-lisp-mode-p)
        (goto-char (treesit-node-start (treesit-node-parent (treesit-node-at (point)))))))

    ;; Forward char if cursor not between in nested round.
    (when not-between-in-round
      (forward-char 1))))

(defun fingertip-is-lisp-mode-p ()
  (or (derived-mode-p 'lisp-mode)
      (derived-mode-p 'emacs-lisp-mode)
      (derived-mode-p 'inferior-emacs-lisp-mode)))

(defun fingertip-nested-round-p ()
  (save-excursion
    (backward-char 1)
    (let ((node-type (fingertip-node-type-at-point)))
      (or (string-equal node-type ")")
          (string-equal node-type "]")
          (string-equal node-type "}")))))

(defun fingertip-wrap-round-pair ()
  (interactive)
  (fingertip-wrap-round-object "(" ")"))

(defun fingertip-wrap-bracket ()
  (interactive)
  (fingertip-wrap-round-object "[" "]"))

(defun fingertip-wrap-curly ()
  (interactive)
  (fingertip-wrap-round-object "{" "}"))

(defun fingertip-unwrap (&optional argument)
  (interactive "P")
  (cond ((derived-mode-p 'web-mode)
         (fingertip-web-mode-element-unwrap))
        ((fingertip-in-string-p)
         (fingertip-unwrap-string argument))
        (t
         (save-excursion
           (fingertip-kill-surrounding-sexps-for-splice argument)
           (backward-up-list)
           (save-excursion
             (forward-sexp)
             (backward-delete-char 1))
           (delete-char 1)
           ;; Try to indent parent expression after unwrap pair.
           ;; This feature just enable in lisp-like language.
           (when (fingertip-is-lisp-mode-p)
             (ignore-errors
               (backward-up-list)
               (indent-sexp)))))))

(defun fingertip-jump-out-pair-and-newline ()
  (interactive)
  (cond ((fingertip-in-string-p)
         (goto-char (cdr (fingertip-current-node-range)))
         (newline-and-indent))
        (t
         ;; Just do when have `up-list' in next step.
         (if (fingertip-ignore-errors (save-excursion (up-list)))
             (let (up-list-point)
               (if (fingertip-is-blank-line-p)
                   ;; Clean current line first if current line is blank line.
                   (fingertip-kill-current-line)
                 ;; Move out of current parentheses and newline.
                 (up-list)
                 (setq up-list-point (point))
                 (newline-and-indent)
                 ;; Try to clean unnecessary whitespace before close parenthesis.
                 ;; This feature just enable in lisp-like language.
                 (when (fingertip-is-lisp-mode-p)
                   (save-excursion
                     (goto-char up-list-point)
                     (backward-char)
                     (when (fingertip-only-whitespaces-before-cursor-p)
                       (fingertip-delete-whitespace-around-cursor))))))
           ;; Try to clean blank line if no pair can jump out.
           (if (fingertip-is-blank-line-p)
               (fingertip-kill-current-line))))))

(defun fingertip-node-text (node)
  (treesit-node-text node t))

(defun fingertip-jump-left ()
  (interactive)
  (let* ((current-node (treesit-node-at (point)))
         (prev-node (treesit-node-prev-sibling current-node))
         (current-node-text (fingertip-node-text current-node))
         (current-point (point)))
    (cond
     ;; Skip blank space.
     ((looking-back "\\s-+" nil)
      (search-backward-regexp "[^ \t\n]" nil t))

     ;; Jump to previous non-blank char if at line beginng.
     ((bolp)
      (forward-line -1)
      (end-of-line)
      (search-backward-regexp "[^ \t\n]" nil t))

     ;; Jump to previous open char.
     ((and (eq major-mode 'web-mode)
           (eq (treesit-node-type current-node) 'raw_text))
      (backward-char 1)
      (while (not (looking-at "\\(['\"<({]\\|[[]\\)")) (backward-char 1)))

     ;; Jump out string if in string.
     ((fingertip-in-string-p)
      (fingertip-jump-string-begin))

     ;; Jump to node start position if current node exist.
     ((> (length current-node-text) 0)
      (goto-char (treesit-node-start current-node))
      (if (equal (point) current-point)
          (backward-char 1)))

     ;; Otherwise, jump to start position of previous node.
     (prev-node
      (goto-char (treesit-node-start prev-node))))))

(defun fingertip-jump-right ()
  (interactive)
  (let* ((current-node (treesit-node-at (point)))
         (next-node (treesit-node-next-sibling current-node))
         (current-node-text (fingertip-node-text current-node))
         (current-point (point)))
    (cond
     ;; Skip blank space.
     ((looking-at "\\s-+")
      (search-forward-regexp "\\s-+" nil t))

     ;; Jump to next non-blank char if at line end.
     ((eolp)
      (forward-line 1)
      (beginning-of-line)
      (search-forward-regexp "\\s-+" nil t))

     ;; Jump into string if at before string open quote char.
     ((eq (char-after) ?\")
      (forward-char))

     ;; Jump to next close char.
     ((and (eq major-mode 'web-mode)
           (eq (treesit-node-type current-node) 'raw_text))
      (while (not (looking-at "\\(['\">)}]\\|]\\)")) (forward-char 1))
      (forward-char 1))

     ;; Jump out string if in string.
     ((fingertip-in-string-p)
      (fingertip-jump-string-end))

     ;; Jump to node end position if current node exist.
     ((> (length current-node-text) 0)
      (goto-char (treesit-node-end current-node))
      (if (equal (point) current-point)
          (forward-char 1)))

     ;; Otherwise, jump to end position of next node.
     (next-node
      (goto-char (treesit-node-end next-node))))))

(defun fingertip-jump-string-begin ()
  (goto-char (car (thing-at-point-bounds-of-string-at-point))))

(defun fingertip-jump-string-end ()
  (goto-char (cdr (thing-at-point-bounds-of-string-at-point))))

(defun fingertip-delete-whitespace-around-cursor ()
  (fingertip-delete-region (save-excursion
                             (search-backward-regexp "[^ \t\n]" nil t)
                             (forward-char)
                             (point))
                           (save-excursion
                             (search-forward-regexp "[^ \t\n]" nil t)
                             (backward-char)
                             (point))))

(defun fingertip-kill-current-line ()
  (fingertip-delete-region (beginning-of-thing 'line) (end-of-thing 'line))
  (back-to-indentation))

(defun fingertip-missing-close ()
  (let ((start-point (point))
        open)
    (save-excursion
      ;; Get open tag.
      (backward-up-list)
      (setq open (char-after))

      ;; Jump to start position and use `check-parens' check unbalance paren.
      (goto-char start-point)
      (ignore-errors
        (check-parens))

      ;; Return missing tag if point change after `check-parens'
      ;; Otherwhere return nil.
      (if (equal start-point (point))
          nil
        open))))

(defun fingertip-backward-delete-in-pair ()
  (backward-delete-char 1)
  (delete-char 1))

(defun fingertip-forward-movein-string ()
  (cond ((and (string= (fingertip-node-type-at-point) "raw_string_literal")
              (eq (char-after) ?`))
         (forward-char 1))
        (t
         (forward-char (length (fingertip-node-text (treesit-node-at (point))))))))

(defun fingertip-is-string-node-p (current-node)
  (or (eq (treesit-node-type current-node) 'string)
      (eq (treesit-node-type current-node) 'string_literal)
      (eq (treesit-node-type current-node) 'interpreted_string_literal)
      (eq (treesit-node-type current-node) 'raw_string_literal)
      (string-equal (treesit-node-type current-node) "\"")))

(defun fingertip-in-empty-backquote-string-p ()
  (let ((current-node (treesit-node-at (point))))
    (and (fingertip-is-string-node-p current-node)
         (string-equal (fingertip-node-text current-node) "``")
         (eq (char-before) ?`)
         (eq (char-after) ?`)
         )))

(defun fingertip-get-parent-bound-info ()
  (let* ((current-node (treesit-node-at (point)))
         (parent-node (treesit-node-parent current-node))
         (parent-bound-start (fingertip-node-text (save-excursion
                                                    (goto-char (treesit-node-start parent-node))
                                                    (treesit-node-at (point)))))
         (parent-bound-end (fingertip-node-text (save-excursion
                                                  (goto-char (treesit-node-end parent-node))
                                                  (backward-char 1)
                                                  (treesit-node-at (point))))))
    (list current-node parent-node parent-bound-start parent-bound-end)))

(defun fingertip-in-empty-string-p ()
  (or (let* ((parent-bound-info (fingertip-get-parent-bound-info))
             (current-node (nth 0 parent-bound-info))
             (parent-node (nth 1 parent-bound-info))
             (string-bound-start (nth 2 parent-bound-info))
             (string-bound-end (nth 3 parent-bound-info)))
        (and (fingertip-is-string-node-p current-node)
             (= (length (fingertip-node-text parent-node)) (+ (length string-bound-start) (length string-bound-end)))
             ))
      (string-equal (fingertip-node-text (treesit-node-at (point))) "\"\"")))

(defun fingertip-backward-delete-in-string ()
  (cond
   ;; Delete empty string if cursor in empty string.
   ((fingertip-in-empty-backquote-string-p)
    (fingertip-delete-empty-backquote-string))
   ((fingertip-in-empty-string-p)
    (fingertip-delete-empty-string))
   ;; Jump left to out of string quote if cursor after open quote.
   ((fingertip-after-open-quote-p)
    (backward-char (length (save-excursion
                             (backward-char 1)
                             (fingertip-node-text (treesit-node-at (point)))))))
   ;; Delete previous character.
   (t
    (backward-delete-char 1))))

(defun fingertip-delete-empty-string ()
  (cond ((string-equal (fingertip-node-text (treesit-node-at (point))) "\"\"")
         (fingertip-delete-region (- (point) 1) (+ (point) 1)))
        (t
         (let* ((current-node (treesit-node-at (point)))
                (node-bound-length (save-excursion
                                     (goto-char (treesit-node-start current-node))
                                     (length (fingertip-node-text (treesit-node-at (point)))))))
           (fingertip-delete-region (- (point) node-bound-length) (+ (point) node-bound-length))))))

(defun fingertip-delete-empty-backquote-string ()
  (fingertip-delete-region (save-excursion
                             (backward-char 1)
                             (point))
                           (save-excursion
                             (forward-char 1)
                             (point))))

(defun fingertip-forward-delete-in-string ()
  (let* ((current-node (treesit-node-at (point)))
         (node-bound-length (save-excursion
                              (goto-char (treesit-node-start current-node))
                              (length (fingertip-node-text (treesit-node-at (point)))))))
    (unless (eq (point) (- (treesit-node-end current-node) node-bound-length))
      (delete-char 1))))

(defun fingertip-unwrap-string (argument)
  (let* ((original-point (point))
         (start+end (fingertip-current-node-range))
         (start (car start+end))
         (end (1- (cdr start+end)))
         (escaped-string (fingertip-escaped-string argument start end original-point))
         (unescaped-string (fingertip-unescape-string escaped-string)))
    (when unescaped-string
      (fingertip-delete-and-insert start end unescaped-string)
      (fingertip-move-cursor original-point argument))))

(defun fingertip-escaped-string (argument start end original-point)
  (cond
   ((not (consp argument))
    (buffer-substring (1+ start) end))
   ((= 4 (car argument))
    (buffer-substring original-point end))
   (t
    (buffer-substring (1+ start) original-point))))

(defun fingertip-delete-and-insert (start end unescaped-string)
  (save-excursion
    (goto-char start)
    (fingertip-delete-region start (1+ end))
    (insert unescaped-string)))

(defun fingertip-move-cursor (original-point argument)
  (unless (and (consp argument) (= 4 (car argument)))
    (goto-char (- original-point 1))))

(defun fingertip-point-at-sexp-start ()
  (save-excursion
    (forward-sexp)
    (backward-sexp)
    (point)))

(defun fingertip-point-at-sexp-end ()
  (save-excursion
    (backward-sexp)
    (forward-sexp)
    (point)))

(defun fingertip-point-at-sexp-boundary (n)
  (cond ((< n 0) (fingertip-point-at-sexp-start))
        ((= n 0) (point))
        ((> n 0) (fingertip-point-at-sexp-end))))

(defun fingertip-kill-surrounding-sexps-for-splice (argument)
  (cond ((or (fingertip-in-string-p)
             (fingertip-in-comment-p))
         (error "Invalid context for splicing S-expressions."))
        ((or (not argument) (eq argument 0)) nil)
        ((or (numberp argument) (eq argument '-))
         (let* ((argument (if (eq argument '-) -1 argument))
                (saved (fingertip-point-at-sexp-boundary (- argument))))
           (goto-char saved)
           (ignore-errors (backward-sexp argument))
           (fingertip-hack-kill-region saved (point))))
        ((consp argument)
         (let ((v (car argument)))
           (if (= v 4)
               (let ((end (point)))
                 (ignore-errors
                   (while (not (bobp))
                     (backward-sexp)))
                 (fingertip-hack-kill-region (point) end))
             (let ((beginning (point)))
               (ignore-errors
                 (while (not (eobp))
                   (forward-sexp)))
               (fingertip-hack-kill-region beginning (point))))))
        (t (error "Bizarre prefix argument `%s'." argument))))

(defun fingertip-unescape-string (string)
  (with-temp-buffer
    (insert string)
    (goto-char (point-min))
    (while (and (not (eobp))
                (search-forward "\\" nil t))
      (delete-char -1)
      (forward-char))
    (condition-case condition
        (progn
          (check-parens)
          (buffer-string))
      (error nil))))

(defun fingertip-hack-kill-region (start end)
  (let ((this-command nil)
        (last-command nil))
    (fingertip-delete-region start end)))

(defun fingertip-backward-kill-internal ()
  (cond (current-prefix-arg
         (kill-line (if (integerp current-prefix-arg)
                        current-prefix-arg
                      1)))
        ((fingertip-in-string-p)
         (fingertip-kill-before-in-string))
        ((or (fingertip-in-comment-p)
             (save-excursion
               (fingertip-skip-whitespace nil (line-beginning-position))
               (bolp)))
         (if (bolp) (fingertip-backward-delete)
           (kill-line 0)))
        (t (fingertip-kill-sexps-backward-on-line))))

(defun fingertip-js-mode-kill-rest-string ()
  (fingertip-delete-region (point)
                           (save-excursion
                             (forward-sexp)
                             (backward-char)
                             (point))))

(defun fingertip-at-raw-string-begin-p ()
  (let ((current-node (treesit-node-at (point))))
    (and (fingertip-is-string-node-p current-node)
         (= (point) (1+ (treesit-node-start current-node)))
         (or (eq (char-before) ?R)
             (eq (char-before) ?r)
             ))))

(defun fingertip-kill-after-in-string ()
  (cond ((or (derived-mode-p 'python-mode)
             (derived-mode-p 'python-ts-mode))
         (fingertip-kill-line-in-string))
        (t
         (if (let ((current-node (treesit-node-at (point))))
               (and (fingertip-is-string-node-p current-node)
                    (> (point) (treesit-node-start current-node))))
             (let* ((parent-bound-info (fingertip-get-parent-bound-info))
                    (current-node (nth 0 parent-bound-info))
                    (current-node-bound-end (fingertip-node-text (save-excursion
                                                                   (goto-char (treesit-node-end current-node))
                                                                   (backward-char 1)
                                                                   (treesit-node-at (point))))))
               (cond ((fingertip-at-raw-string-begin-p)
                      (fingertip-delete-region (treesit-node-start current-node) (treesit-node-end current-node)))
                     ((string-equal current-node-bound-end "'''")
                      (fingertip-delete-region (point) (- (treesit-node-end current-node) (length current-node-bound-end))))
                     ((fingertip-after-open-single-quote-p current-node)
                      (fingertip-kill-line-in-string))
                     (t
                      (fingertip-delete-region (point) (- (treesit-node-end current-node) 1)))))
           (fingertip-kill-line-in-string)))))

(defun fingertip-after-open-single-quote-p (current-node)
  (not (string= (buffer-substring-no-properties (treesit-node-start current-node)
                                                (treesit-node-end current-node))
                (thing-at-point 'string t))))

(defun fingertip-kill-line-in-string ()
  (cond ((save-excursion
           (fingertip-skip-whitespace t (point-at-eol))
           (eolp))
         (kill-line))
        (t
         (kill-region (point) (save-excursion
                                (end-of-thing 'string)
                                (backward-char)
                                (point))))))

(defun fingertip-in-string-escape-p ()
  (let ((oddp nil))
    (save-excursion
      (while (eq (char-before) ?\\ )
        (setq oddp (not oddp))
        (backward-char)))
    oddp))

(defun fingertip-skip-whitespace (trailing-p &optional limit)
  (funcall (if trailing-p 'skip-chars-forward 'skip-chars-backward)
           " \t\n"
           limit))

(defun fingertip-kill-before-in-string ()
  (fingertip-delete-region (point) (1+ (treesit-node-start (treesit-node-at (point))))))

(defun fingertip-skip-whitespace (trailing-p &optional limit)
  (funcall (if trailing-p #'skip-chars-forward #'skip-chars-backward)
           " \t\n"
           limit))

(defun fingertip-kill-sexps-on-line ()
  "Kill forward sexp on the current line."
  (condition-case nil
      (progn
        (when (fingertip-in-char-p)
          (backward-char 2))
        (let* ((begin-point (point))
               (eol (line-end-position))
               (end-of-list-p (fingertip-end-of-list-p begin-point eol)))
          (if (and (not end-of-list-p)
                   (memq (char-before) '(?\) ?\) ?\]))
                   (save-excursion
                     (fingertip-match-paren nil)
                     (> (save-excursion
                          (line-number-at-pos))
                        (save-excursion
                          (goto-char begin-point)
                          (line-number-at-pos)))))
              ;; When `end-of-list-p' is nil.
              ;; We need call `fingertip-match-paren' then check open parentheses point,
              ;; if open parentheses line is bigger than line of `begin-point',
              ;; just kill current line, not continue.
              (progn
                (goto-char begin-point)
                (fingertip-delete-region begin-point eol))

            (when end-of-list-p
              (up-list)
              (backward-char))

            (when (and (not end-of-list-p)
                       (eq (line-end-position) eol))
              (goto-char eol))

            ;; NOTE: Back to previous line if point is at the beginning of line.
            (when (bolp)
              (backward-char 1))
            (fingertip-delete-region begin-point (point)))))
    ;; Delete rest content of line when kill sexp throw `scan-error' error.
    (scan-error (fingertip-delete-region (point) (point-at-eol)))))

(defun fingertip-end-of-list-p (beginning eol)
  (let ((end-of-list-p nil)
        (firstp t))
    (catch 'return
      (while t
        (save-excursion
          (unless (fingertip-ignore-errors (forward-sexp))
            (when (fingertip-ignore-errors (up-list))
              (setq end-of-list-p (eq (line-end-position) eol))
              (throw 'return nil)))
          (if (or (and (not firstp)
                       (eobp))
                  (not (fingertip-ignore-errors (backward-sexp)))
                  (not (eq (line-end-position) eol)))
              (throw 'return nil)))
        (forward-sexp)
        (if (and firstp
                 (eobp))
            (throw 'return nil))
        (setq firstp nil)))
    end-of-list-p))

(defun fingertip-kill-sexps-backward-on-line ()
  "Kill backward sexp on the current line."
  (when (fingertip-in-char-p)
    (forward-char 1))
  (let* ((begin-point (point))
         (bol (line-beginning-position))
         (beg-of-list-p (fingertip-backward-sexps-to-kill begin-point bol)))
    (when beg-of-list-p
      (up-list -1)
      (forward-char))
    (fingertip-delete-region (if (and (not beg-of-list-p) (eq (line-beginning-position) bol))
                                 bol
                               (point))
                             begin-point)))

(defun fingertip-backward-sexps-to-kill (beginning bol)
  (let ((beg-of-list-p nil)
        (lastp t))
    (catch 'return
      (while t
        (save-excursion
          (unless (fingertip-ignore-errors (backward-sexp))
            (when (fingertip-ignore-errors (up-list -1))
              (setq beg-of-list-p (eq (line-beginning-position) bol))
              (throw 'return nil)))
          (if (or (and (not lastp)
                       (bobp))
                  (not (fingertip-ignore-errors (forward-sexp)))
                  (not (eq (line-beginning-position) bol)))
              (throw 'return nil)))
        (backward-sexp)
        (if (and lastp
                 (bobp))
            (throw 'return nil))
        (setq lastp nil)))
    beg-of-list-p))

(defun fingertip-find-parent-node-match (node-types)
  (treesit-parent-until
   (treesit-node-at (point))
   (lambda (parent)
     (member (treesit-node-type parent) node-types))))

(defun fingertip-in-argument-list-p ()
  (fingertip-find-parent-node-match '("argument_list" "arguments" "tuple" "tuple_pattern" "pair" "dictionary" "list")))

(defun fingertip-get-parenthesis-begin-pos (parenthesis-end-pos)
  (save-excursion
    (when parenthesis-end-pos
      (goto-char parenthesis-end-pos)
      (fingertip-match-paren 1)
      (point)
      )))

(defun fingertip-get-parenthesis-end-pos ()
  ;; We check every char after point, if it match ) ] }, and check match parenthesis.
  ;; Return parenthesis end position if found it in current line.
  (save-excursion
    (let ((current-pos (point)))
      (catch 'return
        (while (not (eolp))
          (forward-char)
          (when (and (member (char-before) '(?\) ?\] ?\}))
                     (member (treesit-node-type (treesit-node-at (point))) '(")" "]" "}"))
                     (save-excursion
                       (fingertip-match-paren 1)
                       (when (member (treesit-node-type (treesit-node-at (point))) '("(" "[" "{"))
                         (>= current-pos (point)))))
            (throw 'return (point))
            ))))))

(defun fingertip-common-mode-kill ()
  (cond
   ;; Kill blank line.
   ((fingertip-is-blank-line-p)
    (fingertip-kill-blank-line-and-reindent))
   ;; Kill line if current-prefix-arg is non-nil.
   (current-prefix-arg
    (kill-line (if (integerp current-prefix-arg)
                   current-prefix-arg
                 1)))
   ;; Kill rest characters in string.
   ((fingertip-in-string-p)
    (fingertip-kill-after-in-string))
   ;; Kill line in comment.
   ((fingertip-in-comment-p)
    (kill-line))
   ;; Kill rest characters in parenthesis or sexp.
   (t
    (let* ((parenthesis-end-pos (fingertip-get-parenthesis-end-pos))
           (parenthesis-begin-pos (fingertip-get-parenthesis-begin-pos parenthesis-end-pos)))
      (cond (parenthesis-end-pos
             (if (equal (point) parenthesis-begin-pos)
                 ;; Kill parenthesis if current point is parenthesis begin.
                 (kill-region parenthesis-begin-pos parenthesis-end-pos)
               ;; Kill rest characters in parenthesis.
               (kill-region (point) (- parenthesis-end-pos 1)))
             ;; Try indent after kill action.
             (indent-for-tab-command))
            (t
             ;; Otherwise try `fingertip-kill-sexps-on-line'.
             (fingertip-kill-sexps-on-line)))))))

(defun fingertip-kill-parameters-after-point ()
  (let ((parent-node-end (save-excursion
                           (treesit-node-end (treesit-node-parent (treesit-node-at (point)))))))
    (kill-region (point)
                 (if (member (treesit-node-type (treesit-node-at (point))) '("(" "[" "{"))
                     ;; Delete all list if current node match open bracket.
                     parent-node-end
                   ;; Delete rest parameters in list if cursor in bracket.
                   (1- parent-node-end)))))

(defun fingertip-common-mode-backward-kill ()
  (if (fingertip-is-blank-line-p)
      (fingertip-ignore-errors
       (progn
         (fingertip-kill-blank-line-and-reindent)
         (forward-line -1)
         (end-of-line)))
    (fingertip-backward-kill-internal)))

(defun fingertip-node-range (node)
  (cons (treesit-node-start node)
        (treesit-node-end node)))

(defun fingertip-current-node-range ()
  (fingertip-node-range (treesit-node-at (point))))

(defun fingertip-kill-prepend-space ()
  (fingertip-delete-region (save-excursion
                             (search-backward-regexp "[^ \t\n]" nil t)
                             (forward-char 1)
                             (point))
                           (point)))

(defun fingertip-at-tag-right (tag)
  (save-excursion
    (backward-char 1)
    (string= (fingertip-node-type-at-point) tag)))

(defun fingertip-web-mode-kill ()
  "It's a smarter kill function for `web-mode'."
  (if (fingertip-is-blank-line-p)
      (fingertip-kill-blank-line-and-reindent)
    (cond
     ;; Kill from current point to attribute end position.
     ((string= (fingertip-node-type-at-point) "attribute_value")
      (fingertip-delete-region (point) (treesit-node-end (treesit-node-at (point)))))

     ;; Kill parent node if cursor at attribute or directive node.
     ((or (string= (fingertip-node-type-at-point) "attribute_name")
          (string= (fingertip-node-type-at-point) "directive_name"))
      (fingertip-web-mode-kill-parent-node))

     ;; Jump to next non-blank char if in tag area.
     ((string= (fingertip-node-type-at-point) "self_closing_tag")
      (search-forward-regexp "\\s-+"))

     ;; Clean blank spaces before close tag.
     ((string-equal (fingertip-node-type-at-point) "/>")
      (fingertip-web-mode-clean-spaces-before-tag nil))

     ;; Clean blank spaces before start tag.
     ((string-equal (fingertip-node-type-at-point) ">")
      (fingertip-web-mode-clean-spaces-before-tag t))

     ;; Clean blank space before </
     ((string-equal (fingertip-node-type-at-point) "</")
      (fingertip-web-mode-clean-spaces-before-tag t))

     ;; Kill all tag content if cursor in tag start area.
     ((string= (fingertip-node-type-at-point) "tag_name")
      (fingertip-web-mode-kill-parent-node))

     ;; Kill tag content if cursor at left of <
     ((string-equal (fingertip-node-type-at-point) "<")
      (fingertip-web-mode-kill-grandfather-node))

     ;; Kill string if cursor at start of quote.
     ((string-equal (fingertip-node-type-at-point) "\"")
      (forward-char 1)
      (fingertip-web-mode-kill-parent-node))

     ;; Kill content if in start_tag area.
     ((string= (fingertip-node-type-at-point) "start_tag")
      (cond ((looking-at "\\s-")
             (search-forward-regexp "\\s-+"))
            ((save-excursion
               (fingertip-skip-whitespace t (line-end-position))
               (or (eq (char-after) ?\; )
                   (eolp)))
             (kill-line))))

     ;; JavaScript string not identify by `treesit'
     ;; We need use `fingertip-current-parse-state' test cursor
     ;; whether in string.
     ((and (string= (fingertip-node-type-at-point) "raw_text")
           (save-excursion (nth 3 (fingertip-current-parse-state))))
      (fingertip-js-mode-kill-rest-string))

     ;; Use common kill at last.
     (t
      (fingertip-common-mode-kill)))))

(defun fingertip-web-mode-clean-spaces-before-tag (kill-grandfather-node)
  (cond ((looking-back "\\s-" nil)
         (fingertip-kill-prepend-space))
        ;; Kill tag if nothing in tag area.
        ((fingertip-at-tag-right "tag_name")
         (backward-char 1)
         (if kill-grandfather-node
             (fingertip-web-mode-kill-grandfather-node)
           (fingertip-web-mode-kill-parent-node)))
        (t
         (message "Nothing to kill in tag. ;)"))))

(defun fingertip-web-mode-kill-parent-node ()
  (let ((range (fingertip-node-range (treesit-node-parent (treesit-node-at (point))))))
    (fingertip-delete-region (car range) (cdr range))))

(defun fingertip-web-mode-kill-grandfather-node ()
  (let ((range (fingertip-node-range (treesit-node-parent (treesit-node-parent (treesit-node-at (point)))))))
    (fingertip-delete-region (car range) (cdr range))))

(defun fingertip-web-mode-backward-kill ()
  (message "Backward kill in web-mode is currently not implemented."))

(defun fingertip-kill-blank-line-and-reindent ()
  (fingertip-delete-region (beginning-of-thing 'line) (end-of-thing 'line))
  (back-to-indentation))

(defun fingertip-indent-parent-area ()
  (let ((range (fingertip-node-range (treesit-node-parent (treesit-node-at (point))))))
    (indent-region (car range) (cdr range))))

(defun fingertip-equal ()
  (interactive)
  (cond
   ((derived-mode-p 'web-mode)
    (cond ((or (string= (fingertip-node-type-at-point) "attribute_value")
               (string= (fingertip-node-type-at-point) "raw_text")
               (string= (fingertip-node-type-at-point) "text"))
           (insert "="))
          ;; Insert equal and double quotes if in tag attribute area.
          ((and (string-equal (file-name-extension (buffer-file-name)) "vue")
                (fingertip-vue-in-template-area-p)
                (or (string= (fingertip-node-type-at-point) "directive_name")
                    (string= (fingertip-node-type-at-point) "attribute_name")
                    (string= (fingertip-node-type-at-point) "start_tag")))
           (insert "=\"\"")
           (backward-char 1))
          (t
           (insert "="))))
   (t
    (insert "="))))

(defun fingertip-in-script-area-p ()
  (and (save-excursion
         (search-backward-regexp "<script" nil t))
       (save-excursion
         (search-forward-regexp "</script>" nil t))))

(defun fingertip-vue-in-template-area-p ()
  (and (save-excursion
         (search-backward-regexp "<template>" nil t))
       (save-excursion
         (search-forward-regexp "</template>" nil t))))

(defun fingertip-web-mode-element-wrap ()
  "Like `web-mode-element-wrap', but jump after tag for continue edit."
  (interactive)
  (let (beg end pos tag beg-sep)
    ;; Insert tag pair around select area.
    (save-excursion
      (setq tag (read-from-minibuffer "Tag name? "))
      (setq pos (point))
      (cond
       (mark-active
        (setq beg (region-beginning))
        (setq end (region-end)))
       ((get-text-property pos 'tag-type)
        (setq beg (web-mode-element-beginning-position pos)
              end (1+ (web-mode-element-end-position pos))))
       ((setq beg (web-mode-element-parent-position pos))
        (setq end (1+ (web-mode-element-end-position pos)))))
      (when (and beg end (> end 0))
        (web-mode-insert-text-at-pos (concat "</" tag ">") end)
        (web-mode-insert-text-at-pos (concat "<" tag ">") beg)))

    (when (and beg end)
      ;; Insert return after start tag if have text after start tag.
      (setq beg-sep "")
      (goto-char (+ beg (length (concat "<" tag ">"))))
      (unless (looking-at "\\s-*$")
        (setq beg-sep "\n")
        (insert "\n"))

      ;; Insert return before end tag if have text before end tag.
      (goto-char (+ end (length (concat "<" tag ">")) (length beg-sep)))
      (unless (looking-back "^\\s-*" nil)
        (insert "\n"))

      ;; Insert return after end tag if have text after end tag.
      (goto-char beg)
      (goto-char (+ 1 (web-mode-element-end-position (point))))
      (unless (looking-at "\\s-*$")
        (insert "\n"))

      ;; Indent tag area.
      (let ((indent-beg beg)
            (indent-end (save-excursion
                          (goto-char beg)
                          (+ 1 (web-mode-element-end-position (point)))
                          )))
        (indent-region indent-beg indent-end))

      ;; Jump to start tag, ready for insert tag attributes.
      (goto-char beg)
      (back-to-indentation)
      (forward-char (+ 1 (length tag))))))

(defun fingertip-web-mode-element-unwrap ()
  "Like `web-mode-element-vanish', but you don't need jump parent tag to unwrap.
Just like `paredit-splice-sexp+' style."
  (interactive)
  (save-excursion
    (web-mode-element-parent)
    (web-mode-element-vanish 1)
    (back-to-indentation)))

(defun fingertip-match-paren (arg)
  "Go to the matching parenthesis if on parenthesis , otherwise insert %."
  (interactive "p")
  (cond ((or (fingertip-in-comment-p)
             (fingertip-in-string-p))
         (self-insert-command (or arg 1)))
        ((looking-at "\\s\(\\|\\s\{\\|\\s\[")
         (forward-list))
        ((looking-back "\\s\)\\|\\s\}\\|\\s\\]" nil)
         (backward-list))
        (t
         (cond
          ;; Enhancement the automatic jump of web-mode.
          ((derived-mode-p 'web-mode)
           (fingertip-web-mode-match-paren))
          (t
           (self-insert-command (or arg 1)))))))

;;;;;;;;;;;;;;;;; Utils functions ;;;;;;;;;;;;;;;;;;;;;;

(defun fingertip-wrap (beg end a b)
  "Insert A at position BEG, and B after END. Save previous point position.

A and B are strings."
  (goto-char end)
  (insert b)
  (goto-char beg)
  (insert a))

(defun fingertip-wrap-region (a b)
  "When a region is active, insert A and B around it, and jump after A.

A and B are strings."
  (when (region-active-p)
    (let ((start (region-beginning))
          (end (region-end)))
      (setq mark-active nil)
      (goto-char end)
      (insert b)
      (goto-char start)
      (insert a))))

(defun fingertip-current-parse-state ()
  (let ((point (point)))
    (beginning-of-defun)
    (when (equal point (point))
      (beginning-of-line))
    (parse-partial-sexp (min (point) point)
                        (max (point) point))))

(defun fingertip-after-open-pair-p ()
  (unless (bobp)
    (save-excursion
      (let ((syn (char-syntax (char-before))))
        (or (eq syn ?\()
            (and (eq syn ?_)
                 (eq (char-before) ?\{)))
        ))))

(defun fingertip-after-close-pair-p ()
  (unless (bobp)
    (save-excursion
      (let ((syn (char-syntax (char-before))))
        (or (eq syn ?\) )
            (eq syn ?\" )
            (and (eq syn ?_ )
                 (eq (char-before) ?\})))))))

(defun fingertip-before-open-pair-p ()
  (unless (eobp)
    (save-excursion
      (let ((syn (char-syntax (char-after))))
        (or (eq syn ?\( )
            (and (eq syn ?_)
                 (eq (char-after) ?\{)))))))

(defun fingertip-before-close-pair-p ()
  (unless (eobp)
    (save-excursion
      (let ((syn (char-syntax (char-after))))
        (or (eq syn ?\) )
            (and (eq syn ?_)
                 (eq (char-after) ?\})))))))

(defun fingertip-in-empty-pair-p ()
  (ignore-errors
    (save-excursion
      (or (and (eq (char-syntax (char-before)) ?\()
               (eq (char-after) (matching-paren (char-before))))
          (and (eq (char-syntax (char-before)) ?_)
               (eq (char-before) ?\{)
               (eq (char-syntax (char-after)) ?_)
               (eq (char-after) ?\})
               )))))

(defun fingertip-node-type-at-point ()
  (ignore-errors (treesit-node-type (treesit-node-at (point)))))

(defun fingertip-in-string-p ()
  (save-excursion
    (or
     ;; If node type is 'string, point must at right of string open quote.
     (ignore-errors
       (let ((current-node (treesit-node-at (point))))
         (and (fingertip-is-string-node-p current-node)
              (> (point) (treesit-node-start current-node))
              )))

     (nth 3 (fingertip-current-parse-state))

     (fingertip-before-string-close-quote-p))))

(defun fingertip-in-single-quote-string-p ()
  (ignore-errors
    (let ((parent-node-text (fingertip-node-text (treesit-node-parent (treesit-node-at (point))))))
      (and (fingertip-in-string-p)
           (> (length parent-node-text) 1)
           (string-equal (substring parent-node-text 0 1) "'")))))

(defun fingertip-before-string-close-quote-p ()
  (let ((current-node (treesit-node-at (point))))
    (and
     (= (point) (treesit-node-start current-node))
     (string-equal (treesit-node-type current-node) "\"")
     (save-excursion
       (forward-char (length (fingertip-node-text current-node)))
       (not (fingertip-is-string-node-p (treesit-node-at (point))))
       ))))

(defun fingertip-after-open-quote-p ()
  (and (not (string-equal (fingertip-node-type-at-point) "\""))
       (save-excursion
         (backward-char 1)
         (string-equal (fingertip-node-type-at-point) "\""))))

(defun fingertip-before-string-open-quote-p ()
  (save-excursion
    (and (not (fingertip-in-string-p))
         (not (fingertip-in-empty-string-p))
         (or (string-equal (fingertip-node-type-at-point) "\"")
             (string= (fingertip-node-type-at-point) "raw_string_literal")))))

(defun fingertip-in-comment-p ()
  (save-excursion
    (and (nth 4 (fingertip-current-parse-state))
         (string= (fingertip-node-type-at-point) "comment"))))

(defun fingertip-in-char-p (&optional argument)
  (save-excursion
    (let ((argument (or argument (point))))
      (and (eq (char-before argument) ?\\ )
           (not (eq (char-before (1- argument)) ?\\ ))))))

(defun fingertip-is-blank-line-p ()
  (save-excursion
    (beginning-of-line)
    (looking-at "[[:space:]]*$")))

(defun fingertip-only-whitespaces-before-cursor-p ()
  (save-excursion
    (let ((string-before-cursor
           (buffer-substring
            (save-excursion
              (beginning-of-line)
              (point))
            (point))))
      (equal (length (string-trim string-before-cursor)) 0))))

(defun fingertip-newline (arg)
  (interactive "p")
  (cond
   ;; Just newline if in string or comment.
   ((or (fingertip-in-comment-p)
        (fingertip-in-string-p))
    (newline arg))
   ((derived-mode-p 'inferior-emacs-lisp-mode)
    (ielm-return))
   ;; Newline and indent region if cursor in parentheses and character is not blank after cursor.
   ((and (looking-back "(\s*\\|{\s*\\|\\[\s*" nil)
         (looking-at-p "\s*)\\|\s*}\\|\s*\\]"))
    ;; Insert blank below at parentheses.
    (newline arg)
    (open-line 1)
    (indent-according-to-mode)
    ;; Indent close parentheses line.
    (save-excursion
      (search-forward-regexp "\s*)\\|\s*}\\|\s*\\]" nil t)
      (indent-according-to-mode)))
   ;; Newline and indent.
   (t
    (newline arg)
    (indent-according-to-mode))))

(defun fingertip-jump-up ()
  (interactive)
  (ignore-errors
    (treesit-beginning-of-defun)))

;; Integrate with eldoc
(with-eval-after-load 'eldoc
  (eldoc-add-command-completions
   "fingertip-"))

(provide 'fingertip)

;;; fingertip.el ends here
