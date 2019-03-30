;;; dry-container-find.el --- a tool for searching dry-container dependencies with helm completion

;; Author: Vitalii Pecherin
;; Version: 0.1
;; URL: https://github.com/we138/dry-container-find
;; Package-Requires: ((emacs "25") (helm "3.1"))
;; Keywords: dry-container, hanami, find, container

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

(require 'helm)

(defun dry-container-find--looking-dotfiles (path)
  (let ((formatted-path (replace-regexp-in-string "\n\\'" "" path)))
    (if (or (= (length formatted-path) 0) (file-exists-p (concat formatted-path "/.git")))
        formatted-path (dry-container-find--looking-dotfiles (string-join (reverse (cdr (reverse (split-string formatted-path "/")))) "/"))
        )
    )
  )

(defun dry-container-find--project-root ()
  (dry-container-find--looking-dotfiles (dry-container-find--current-path))
  )

(defun dry-container-find--current-path ()
  (with-temp-buffer
    (call-process "pwd" nil t t)
    (buffer-string)
    )
  )

(defun dry-container-find--list-project-files ()
  (setq default-directory (dry-container-find--project-root))
  (with-temp-buffer
    (process-file "git" nil t t "ls-files")
    (split-string (buffer-string) "\n" t)
    )
  )

(defun dry-container-find--open-file (candidate)
  (find-file (concat default-directory "/" (car (split-string candidate ":"))))
  )

(defun dry-container-find--helm-buffer (path)
  (helm :sources (helm-build-in-buffer-source "dry-container-find"
                   :action (helm-make-actions "Open file" #'dry-container-find--open-file)
                   :data (dry-container-find--list-project-files))
        :input path
        :buffer "*dry-container-find*")
  )

(defun dry-container-find-container-dependency (start end)
  (interactive "r")
  (if (use-region-p)
      (let ((regionp (buffer-substring start end)))
        (deactivate-mark)
        (dry-container-find--helm-buffer regionp))))
