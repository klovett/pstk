;;;; pstk-make-test.scm

;;;

(use test)

;;

(use pstk-make)

;;

(test-begin "pstk-make")

(define-values (tk$1 $1) (pstk))
(test-assert tk$1)
(test-assert $1)

(define-values (tk$2 $2) (pstk))
(test-assert tk$2)
(test-assert $2)

;;

(test-group "tk/wm"
  (test-assert ($1 tk/wm 'aspect tk$1))
  (test-assert ($1 tk/wm 'attributes tk$1))
  (test "passive" ($1 tk/wm 'focusmodel tk$1))
  (test-assert ($1 tk/wm 'geometry tk$1))
)

(test-group "tk/winfo"
  (test-assert ($1 tk/winfo 'height tk$1))
  (test-assert ($1 tk/winfo 'width tk$1))
  (test-assert ($1 tk/winfo 'screenheight tk$1))
  (test-assert ($1 tk/winfo 'screenwidth tk$1))
)

(test-group "tk/wm"
  (test-assert ($2 tk/wm 'aspect tk$2))
  (test-assert ($2 tk/wm 'attributes tk$2))
  (test "passive" ($2 tk/wm 'focusmodel tk$2))
  (test-assert ($2 tk/wm 'geometry tk$2))
)

(test-group "tk/winfo"
  (test-assert ($2 tk/winfo 'height tk$2))
  (test-assert ($2 tk/winfo 'width tk$2))
  (test-assert ($2 tk/winfo 'screenheight tk$2))
  (test-assert ($2 tk/winfo 'screenwidth tk$2))
)

($2 tk-end)
($1 tk-end)

(test-end "pstk-make")

;;

(test-exit)
