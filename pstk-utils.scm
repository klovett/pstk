;;;; pstk-utils.scm
;;;; Kon Lovett, May '18

(module pstk-utils

(export
  tk-doto
  tk-with)

(import scheme chicken)

;;;

(define-syntax tk-doto
  (syntax-rules ()
    ((_ (?reciever ?a0) (?operation ?arg0 ...) ...)
      (let ((reciever ?reciever))
        (reciever ?a0 '?operation ?arg0 ...)
        ... ) )
    ((_ ?reciever (?operation ?arg0 ...) ...)
      (let ((reciever ?reciever))
        (reciever '?operation ?arg0 ...)
        ... ) ) ) )

(define-syntax tk-with
  (syntax-rules ()
    ((_ (?reciever ?a0) (?arg0 ...) ...)
      (let ((reciever ?reciever))
        (reciever ?a0 ?arg0 ...)
        ... ) )
    ((_ ?reciever (?arg0 ...) ...)
      (let ((reciever ?reciever))
        (reciever ?arg0 ...)
        ... ) ) ) )

) ;module pstk-utils
