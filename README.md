# What is fingertip.el ?
fingertip.el is a plugin that provides grammatical edit base on treesit

## Installation
1. Install Emacs 29 or above
2. Clone or download this repository (path of the folder is the `<path-to-fingertip>` used below).

In your `~/.emacs`, add the following two lines:
```Elisp
(add-to-list 'load-path "<path-to-fingertip>") ; add fingertip to your load-path
(require 'fingertip)
```

## Enabled in the specified programming language
Not all programming languages ​​are suitable for parenthesis auto-completion.
You can add fingertip.el to the programming language mode like below:

```Elisp
(dolist (hook (list
               'c-mode-common-hook
               'c-mode-hook
               'c++-mode-hook
               'java-mode-hook
               'haskell-mode-hook
               'emacs-lisp-mode-hook
               'lisp-interaction-mode-hook
               'lisp-mode-hook
               'maxima-mode-hook
               'ielm-mode-hook
               'sh-mode-hook
               'makefile-gmake-mode-hook
               'php-mode-hook
               'python-mode-hook
               'js-mode-hook
               'go-mode-hook
               'qml-mode-hook
               'jade-mode-hook
               'css-mode-hook
               'ruby-mode-hook
               'coffee-mode-hook
               'rust-mode-hook
               'rust-ts-mode-hook
               'qmake-mode-hook
               'lua-mode-hook
               'swift-mode-hook
               'web-mode-hook
               'markdown-mode-hook
               'llvm-mode-hook
               'conf-toml-mode-hook
               'nim-mode-hook
               'typescript-mode-hook
               'c-ts-mode-hook
               'c++-ts-mode-hook
               'cmake-ts-mode-hook
               'toml-ts-mode-hook
               'css-ts-mode-hook
               'js-ts-mode-hook
               'json-ts-mode-hook
               'python-ts-mode-hook
               'bash-ts-mode-hook
               'typescript-ts-mode-hook
               ))
  (add-hook hook #'(lambda () (fingertip-mode 1))))
```

Then binding below fingertip.el commands with below keystrokes:

```Elisp
(define-key fingertip-mode-map (kbd "(") 'fingertip-open-round)
(define-key fingertip-mode-map (kbd "[") 'fingertip-open-bracket)
(define-key fingertip-mode-map (kbd "{") 'fingertip-open-curly)
(define-key fingertip-mode-map (kbd ")") 'fingertip-close-round)
(define-key fingertip-mode-map (kbd "]") 'fingertip-close-bracket)
(define-key fingertip-mode-map (kbd "}") 'fingertip-close-curly)
(define-key fingertip-mode-map (kbd "=") 'fingertip-equal)

(define-key fingertip-mode-map (kbd "（") 'fingertip-open-chinese-round)
(define-key fingertip-mode-map (kbd "「") 'fingertip-open-chinese-bracket)
(define-key fingertip-mode-map (kbd "【") 'fingertip-open-chinese-curly)
(define-key fingertip-mode-map (kbd "）") 'fingertip-close-chinese-round)
(define-key fingertip-mode-map (kbd "」") 'fingertip-close-chinese-bracket)
(define-key fingertip-mode-map (kbd "】") 'fingertip-close-chinese-curly)

(define-key fingertip-mode-map (kbd "%") 'fingertip-match-paren)
(define-key fingertip-mode-map (kbd "\"") 'fingertip-double-quote)
(define-key fingertip-mode-map (kbd "'") 'fingertip-single-quote)

(define-key fingertip-mode-map (kbd "SPC") 'fingertip-space)
(define-key fingertip-mode-map (kbd "RET") 'fingertip-newline)

(define-key fingertip-mode-map (kbd "M-o") 'fingertip-backward-delete)
(define-key fingertip-mode-map (kbd "C-d") 'fingertip-forward-delete)
(define-key fingertip-mode-map (kbd "C-k") 'fingertip-kill)

(define-key fingertip-mode-map (kbd "M-\"") 'fingertip-wrap-double-quote)
(define-key fingertip-mode-map (kbd "M-'") 'fingertip-wrap-single-quote)
(define-key fingertip-mode-map (kbd "M-[") 'fingertip-wrap-bracket)
(define-key fingertip-mode-map (kbd "M-{") 'fingertip-wrap-curly)
(define-key fingertip-mode-map (kbd "M-(") 'fingertip-wrap-round)
(define-key fingertip-mode-map (kbd "M-)") 'fingertip-unwrap)

(define-key fingertip-mode-map (kbd "M-p") 'fingertip-jump-right)
(define-key fingertip-mode-map (kbd "M-n") 'fingertip-jump-left)
(define-key fingertip-mode-map (kbd "M-:") 'fingertip-jump-out-pair-and-newline)

(define-key fingertip-mode-map (kbd "C-j") 'fingertip-jump-up)
```
