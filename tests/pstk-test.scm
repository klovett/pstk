;;;; pstk-test.scm

;;;

(use test)

;;

(use pstk)

;;

(test-begin "pstk")

(tk-start)

;;

(test-group "tk/wm"
  (test-assert (tk/wm 'aspect tk))
  (test-assert (tk/wm 'attributes tk))
  (test "passive" (tk/wm 'focusmodel tk))
  (test-assert (tk/wm 'geometry tk))
)

(test-group "tk/winfo"
  (test-assert (tk/winfo 'height tk))
  (test-assert (tk/winfo 'width tk))
  (test-assert (tk/winfo 'screenheight tk))
  (test-assert (tk/winfo 'screenwidth tk))
)

;;

(use pstk-geometry)

(test-group "pstk-geometry"
  (let (
    (wd (string->number (tk/winfo 'width tk)))
    (ht (string->number (tk/winfo 'height tk)))
    (x (string->number (tk/winfo 'x tk)))
    (y (string->number (tk/winfo 'y tk)))
    (geom (string->tk-geometry (tk/wm 'geometry tk))) )
  (test "winfo & wm agree size" (make-tk-size wd ht) (tk-geometry-size geom))
  (test "winfo & wm agree position" (make-tk-position x y) (tk-geometry-position geom)) )
)

;;

(tk-end)

(test-end "pstk")

;;

(test-exit)
