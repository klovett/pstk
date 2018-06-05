;;;; pstk-geometry.scm
;;;; Kon Lovett, May '18

(module pstk-geometry

(export
  ;
  make-tk-size
  tk-size?
  string->tk-size
  tk-size->string
  tk-size-width
  tk-size-height
  ;
  make-tk-position
  tk-position?
  string->tk-position
  tk-position->string
  tk-position-x
  tk-position-y
  ;
  make-tk-geometry
  tk-geometry?
  string->tk-geometry
  tk-geometry->string
  tk-geometry-size
  tk-geometry-position)

(import scheme chicken)
(use
  utf8 utf8-srfi-13
  irregex)

;;;

;; Geometry Utils

;geometry : [=] [size] [position]

;    size : widthxheight

;position : widthxheight ±x±y

;"=200x200+74-43" => ((200 . 200) . (74 . -43))
;       "200x200" => ((200 . 200) . #f)
;        "+74-43" => (#f . (74 . -43))
;             "=" => #f

(define-type tk-size (pair number number))

(define-type tk-position (pair number number))

(define-type tk-geometry (pair (or boolean tk-size) (or boolean tk-position)))

;NOTE does not enforce positive? constriant for size

(: string->tk-number (* --> (or boolean number)))
;
(define (string->tk-number x)
  (and (string? x) (string->number x)) )

(: ->tk-number (* --> (or boolean number)))
;
(define (->tk-number x)
  (or (string->tk-number x) (and (fixnum? x) x)) )

;;

(define SIZE-SRE '(? (: ($ integer) "x" ($ integer))))

(define SIZE-IRX (sre->irregex SIZE-SRE
  'utf8 'single-line 'case-insensitive 'fast 'small))

(: make-tk-size ((or boolean string number) (or boolean string number) --> tk-size))
;
(define (make-tk-size wd ht)
  (if (or (not wd) (not ht))
    #f
    `(,(->tk-number wd) . ,(->tk-number ht)) ) )

(: tk-size? (* -> boolean : tk-size))
;
(define (tk-size? obj)
  (pair? obj) )

(: tk-size-width (tk-size --> (or boolean fixnum)))
;
(define (tk-size-width sz) (car sz))

(: tk-size-height (tk-size --> (or boolean fixnum)))
;
(define (tk-size-height sz) (cdr sz))

(: string->tk-size ((or boolean string) --> (or boolean tk-size)))
;
(define (string->tk-size str)
  (and
    str
    (let (
      (res (irregex-match SIZE-IRX str)) )
      (and
        (irregex-match-data? res) (fx= 2 (irregex-match-num-submatches res)))
        (make-tk-size (irregex-match-substring res 1) (irregex-match-substring res 2)) ) ) )

(: tk-size->string ((or boolean tk-size) --> string))
;
(define (tk-size->string sz)
  (if (not sz)
    ""
    (string-append
      (number->string (tk-size-width sz))
      "x"
      (number->string (tk-size-height sz))) ) )

;;

(define POSITION-SRE '(? (: ($ (: (or "+" "-") integer)) ($ (: (or "+" "-") integer)))))

(define POSITION-IRX (sre->irregex POSITION-SRE
  'utf8 'single-line 'case-insensitive 'fast 'small))

(: make-tk-position ((or boolean string number) (or boolean string number) --> tk-position))
;
(define (make-tk-position x y)
  (if (or (not x) (not y))
    #f
    `(,(->tk-number x) . ,(->tk-number y)) ) )

(: tk-position? (* -> boolean : tk-position))
;
(define (tk-position? obj)
  (pair? obj) )

(: tk-position-x (tk-position --> (or boolean fixnum)))
;
(define (tk-position-x ps) (car ps))

(: tk-position-y (tk-position --> (or boolean fixnum)))
;
(define (tk-position-y ps) (cdr ps))

(: string->tk-position ((or boolean string) --> (or boolean tk-position)))
;
(define (tk-position-value->string val)
  (string-append
    (if (fx<= 0 val) "+" "")
    (number->string val)) )

(define (string->tk-position str)
  (and
    str
    (let (
      (res (irregex-match POSITION-IRX str)) )
      (and
        (irregex-match-data? res) (fx= 2 (irregex-match-num-submatches res)))
        (make-tk-size (irregex-match-substring res 1) (irregex-match-substring res 2)) ) ) )

(: tk-position->string ((or boolean tk-position) --> string))
;
(define (tk-position->string ps)
  (if (not ps)
    ""
    (string-append
      (tk-position-value->string (tk-position-x ps))
      (tk-position-value->string (tk-position-y ps))) ) )

;;

(define GEOMETRY-SRE `(:
  (? #\=)
  (? ($ (: integer "x" integer)))
  (? ($ (: (or "+" "-") integer (or "+" "-") integer)))))

(define GEOMETRY-IRX (sre->irregex GEOMETRY-SRE
  'utf8 'single-line 'case-insensitive 'fast 'small))

(: make-tk-geometry ((or boolean string tk-size) (or boolean string tk-position) --> tk-geometry))
;
(define (make-tk-geometry sz ps)
  (if (and (not sz) (not ps))
      #f
      `(,sz . ,ps) ) )

(: tk-geometry? (* -> boolean : tk-geometry))
;
(define (tk-geometry? obj)
  (pair? obj) )

(: tk-geometry-size (tk-geometry --> (or boolean tk-size)))
;
(define (tk-geometry-size x) (car x))

(: tk-geometry-position (tk-geometry --> (or boolean tk-position)))
;
(define (tk-geometry-position x) (cdr x))

(: string->tk-geometry ((or boolean string) --> (or boolean tk-geometry)))
;
(define (string->tk-geometry str)
  (and
    str
    (let (
      (res (irregex-match GEOMETRY-IRX str)) )
      (if (and (irregex-match-data? res) (fx= 2 (irregex-match-num-submatches res)))
        (make-tk-geometry
          (string->tk-size (irregex-match-substring res 1))
          (string->tk-position (irregex-match-substring res 2)))
        (error 'string->tk-geometry "improper tk-geomety" str)) ) ) )

(: tk-geometry->string ((or boolean tk-geometry) --> string))
;
(define (tk-geometry->string geom)
  (if (not geom)
    ""
    (let (
      (sz (tk-geometry-size geom))
      (ps (tk-geometry-position geom)) )
      (string-append
        "="
        (tk-size->string sz)
        (tk-position->string ps)) ) ) )

) ;module pstk-geometry
