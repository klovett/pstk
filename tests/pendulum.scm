;;;;

(use pstk-make)
(use pstk-utils)
(use srfi-18)

(define PENDULUM-COUNT 1)

(define PI 3.14159)

(define *conv-radians* (fp/ PI 180.0))

(define *length* 150.)

(define *home-x* 160)
(define *home-y* 25)

(define (fpavg a b) (fp/ (fp+ a b) 2.0))

;;; The main event loop and graphics context

(define (pendulm-thread tk $)

  (define *theta* 45.0)
  (define *d-theta* 0.0)

  ;;; redraw the pendulum on canvas
  ;;; - uses angle and length to compute new (x,y) position of bob
  (define (show-pendulum canvas)
    (let* (
      (pendulum-angle (fp* *conv-radians* *theta*))
      (x (fx+ *home-x* (inexact->exact (round (fp* *length* (sin pendulum-angle))))))
      (y (fx+ *home-y* (inexact->exact (round (fp* *length* (cos pendulum-angle)))))) )
      (canvas 'coords 'rod *home-x* *home-y* x y)
      (canvas 'coords 'bob (fx- x 15) (fx- y 15) (fx+ x 15) (fx+ y 15))) )

  ;;; estimates new angle of pendulum
  (define (recompute-angle)
    ;
    (let* (
      (scaling (fp/ 3000.0 (fp* *length* *length*)))
      ;first estimate
      (first-dd-theta (fpneg (fp* (sin (fp* *theta* *conv-radians*)) scaling)))
      (mid-d-theta (fp+ *d-theta* first-dd-theta))
      (mid-theta (fp+ *theta* (fpavg *d-theta* mid-d-theta)))
      ;second estimate
      (mid-dd-theta (fpneg (fp* (sin (fp* mid-theta *conv-radians*)) scaling)))
      (mid-d-theta-2 (fp+ *d-theta* (fpavg first-dd-theta mid-dd-theta)))
      (mid-theta-2 (fp+ *theta* (fpavg *d-theta* mid-d-theta-2)))
      ;again first
      (mid-dd-theta-2 (fpneg (fp* (sin (fp* mid-theta-2 *conv-radians*)) scaling)))
      (last-d-theta (fp+ mid-d-theta-2 mid-dd-theta-2))
      (last-theta (fp+ mid-theta-2 (fpavg mid-d-theta-2 last-d-theta)))
      ;again second
      (last-dd-theta (fpneg (fp* (sin (fp* last-theta *conv-radians*)) scaling)))
      (last-d-theta-2 (fp+ mid-d-theta-2 (fpavg mid-dd-theta-2 last-dd-theta)))
      (last-theta-2 (fp+ mid-theta-2 (fpavg mid-d-theta-2 last-d-theta-2))))
      ;put values back in globals
      (set! *d-theta* last-d-theta-2)
      (set! *theta* last-theta-2)) )

  ;;; move the pendulum and repeat after 20ms
  (define (animate canvas)
    (recompute-angle)
    (show-pendulum canvas)
    ($ tk/after 20 (lambda () (animate canvas))) )

  ($ tk/wm 'title tk "Pendulum Animation")

  (let (
    (canvas (tk 'create-widget 'canvas)) )
    ;layout the canvas
    ($ tk/grid canvas column: 0 row: 0)
    (tk-doto canvas
      (create 'line 0 25 320 25 tags: 'plate width: 2 fill: 'grey50)
      (create 'oval 155 20 165 30 tags: 'pivot outline: "" fill: 'grey50)
      (create 'line 1 1 1 1 tags: 'rod width: 3 fill: 'black)
      (create 'oval 1 1 2 2 tags: 'bob outline: 'black fill: 'yellow) )
    ;exit button
    (let (
      (cancel
        (tk 'create-widget 'button
          text: "Cancel"
          command: (lambda () ($ tk-end)))) )
      ($ tk/grid cancel column: 0 row: 1 pady: 5) )
    ;
    (make-thread
      (lambda ()
        ;; get everything started
        (show-pendulum canvas)
        ($ tk/after 500 (lambda () (animate canvas)))
        ($ tk-event-loop))) ) )

;;

(define *pendulums* '())

(do ((i 0 (add1 i)))
    ((= PENDULUM-COUNT i) )
  (let-values (
    ((tk $) (pstk)) )
    (set! *pendulums* (cons (pendulm-thread tk $) *pendulums*)) ) )

(for-each thread-start! *pendulums*)

(for-each thread-join! *pendulums*)
