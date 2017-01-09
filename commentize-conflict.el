;;; commentize-conflict.el --- Fix syntax analysis broken by conflict markers

;; Copyright (C) 2017- zk_phi

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

;; Author: zk_phi
;; URL: http://hins11.yu-yake.com/
;; Version: 0.0.0
;; Package-Requires: ((emacs "24.3"))

;;; Commentary:

;; * description
;;
;; This package provides a minor-mode which advices major modes to
;; treat git conflict markers and "their" changes as comments, so that
;; they will not break major-mode's syntax-highlighting.
;;
;; * Installation
;;
;; Put this scrpit into a 'load-path'ed directory, and load it in your
;; init file.
;;
;;   (require 'commentize-conflict)
;;
;; and add hook to the modes you want to enable the feature.
;;
;;   (add-hook 'prog-mode-hook 'commentize-conflict-mode)

;;; Change Log:

;; 0.0.0 text release

;;; Code:

(defvar commentize-conflict--orig-propertize-fn nil
  "Major-mode's original `syntax-propertize-function'.")

(defun commentize-conflict--propertize-fn (b e)
  "Put syntax properties to conflictions in between B and E."
  (goto-char b)
  (let (tmp lst)
    ;; jump backward to conflict markers
    (search-backward-regexp "^<<<<<<< [^\s\t].+$" nil t)
    (setq b (point))
    ;; search all conflictoins between B and E
    (while (and (< (point) e) (search-forward-regexp "^<<<<<<< [^\s\t].+$" e t))
      (push (cons (match-beginning 0) (point-at-eol)) lst)
      (when (search-forward-regexp "^=======$" nil t)
        (setq tmp (match-beginning 0))
        (when (search-forward-regexp "^>>>>>>> [^\s\t].+$" nil t)
          (push (cons tmp (match-end 0)) lst))))
    ;; commentize conflictions
    (dolist (pair (nreverse lst))
      (when commentize-conflict--orig-propertize-fn
        (funcall commentize-conflict--orig-propertize-fn b (1- (car pair))))
      (remove-text-properties (car pair) (1+ (cdr pair)) '(syntax-table))
      (put-text-property (car pair) (1+ (car pair)) 'syntax-table '(14))
      (put-text-property (cdr pair) (1+ (cdr pair)) 'syntax-table '(14))
      (setq b (1+ (cdr pair))))))

;;;###autoload
(define-minor-mode commentize-conflict-mode
  "Minor mode to fix syntax analysis broken by conflict markers."
  :init-value nil
  :global nil
  :lighter " CmCn"
  (cond (commentize-conflict-mode
         (setq-local commentize-conflict--orig-propertize-fn syntax-propertize-function)
         (setq-local syntax-propertize-function 'commentize-conflict--propertize-fn)
         (font-lock-refresh-defaults))
        (t
         (setq-local syntax-propertize-function commentize-conflict--orig-propertize-fn)
         (font-lock-refresh-defaults))))

;; + provide

(provide 'commentize-conflict)

;;; commentize-conflict.el ends here
