
(define EGG-NAME "pstk")

;chicken-install invokes as "<csi> -s run.scm <eggnam> <eggdir>"

(use files)

;no -disable-interrupts
(define *csc-options* "-inline-global -scrutinize -optimize-leaf-routines -local -inline -specialize -unsafe -no-trace -no-lambda-info -clustering -lfa2")

(define *args* (argv))

(define (test-name #!optional (eggnam EGG-NAME))
  (string-append eggnam "-test") )

(define (egg-name #!optional (def EGG-NAME))
  (cond
    ((<= 4 (length *args*))
      (cadddr *args*) )
    (def
      def )
    (else
      (error 'test "cannot determine egg-name") ) ) )

;;;

(set! EGG-NAME (egg-name))

(define (run-csi-test tstnam)
  (system (string-append "csi -s " (make-pathname #f tstnam "scm"))) )

(define (run-csc-test tstnam cscopts)
  (system (string-append "csc" " " cscopts " " (make-pathname #f tstnam "scm")))
  (system (make-pathname (cond-expand (unix "./") (else #f)) tstnam)) )

(define (run-test* tstnam cscopts)
  (print "*** csi ***")
  (run-csi-test tstnam)
  (newline)
  (print "*** csc (" cscopts ") ***")
  (run-csc-test tstnam cscopts) )

(define (run-test #!optional (test EGG-NAME) (cscopts *csc-options*))
  (let ((tstnam (test-name test)))
    (run-test* tstnam cscopts) ) )

(define (run-tests tstnams #!optional (cscopts *csc-options*))
  (for-each (cut run-test <> cscopts) tstnams) )

;;;

(run-test "pstk-make")
(run-test "pstk")

#;
(for-each (cut run-csc-test <> *csc-options*) '(
  "pendulum"
  "text-editor"
  "treeview"
  "widgets"))
