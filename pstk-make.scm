;;;; pstk-make.scm
;;;; Kon Lovett, May '18

(module pstk-make

(;export
  ;;
  tk-eval
  tk-id->widget
  tk-var
  tk-get-var
  tk-set-var!
  tk-start
  tk-end
  tk-dispatch-event
  tk-event-loop
  tk-wait-for-window
  tk-wait-until-visible
  tk-with-lock
  ;
  tk/after
  tk/bell
  tk/update
  tk/clipboard
  tk/bgerror
  tk/bind
  tk/bindtags
  tk/destroy
  tk/event
  tk/focus
  tk/grab
  tk/grid
  tk/image
  tk/lower
  tk/option
  tk/pack
  tk/place
  tk/raise
  tk/selection
  tk/choose-color
  tk/choose-directory
  tk/dialog
  tk/get-open-file
  tk/get-save-file
  tk/message-box
  tk/focus-follows-mouse
  tk/focus-next
  tk/focus-prev
  tk/popup
  tk/appname
  tk/caret
  tk/scaling
  tk/useinputmethods
  tk/wait
  tk/windowingsystem
  tk/wm
  tk/winfo
  ;
  ttk/available-themes
  ttk/set-theme
  ttk/style
  ttk-map-widgets
  ;;
  tk
  pstk-start-program
  pstk-start
  pstk
  make-pstk)

(import scheme chicken)
(use
  (only numbers number? number->string string->number)
  (only posix process)
  (only extras read-line)
  (only data-structures string-translate* string-intersperse)
  (only srfi-1 proper-list? reverse! iota)
  (only utf8 string-ref string-length substring string-split ->string)
  (only utf8-srfi-13 string-concatenate string-null? string-prefix? string-trim))

;;;

(declare
  (bound-to-procedure
    ##sys#signal-hook) )

(define (signal-bounds-error loc . objs)
  (apply ##sys#signal-hook #:bounds-error loc "invalid index" objs) )

;internal debugging aids

(define *wish-debug-input?* #f)
(define *wish-debug-output?* #f)

;;

;;

(define nl (string #\newline))

(cond-expand
  (chicken
    (include "pstk-chicken-init") )
  (else
    (define tk-init-string (string-intersperse '(
      "package require Tk"
      "if {[package version tile] != \"\"} {"
      "    package require tile"
      "}"
      ""
      "namespace eval AutoName {"
      "    variable c 0"
      "    proc autoName {{result \\#\\#}} {"
      "        variable c"
      "        append result [incr c]"
      "    }"
      "    namespace export *"
      "}"
      ""
      "namespace import AutoName::*"
      ""
      "proc callToScm {callKey args} {"
      "    global scmVar"
      "    set resultKey [autoName]"
      "    puts \"(call $callKey \\\"$resultKey\\\" $args)\""
      "    flush stdout"
      "    vwait scmVar($resultKey)"
      "    set result $scmVar($resultKey)"
      "    unset scmVar($resultKey)"
      "    set result"
      "}"
      ""
      "proc tclListToScmList {l} {"
      "    switch [llength $l] {"
      "        0 {"
      "            return ()"
      "        }"
      "        1 {"
      "            if {[string range $l 0 0] eq \"\\#\"} {"
      "                return $l"
      "            }"
      "            if {[regexp {^[0-9]+$} $l]} {"
      "                return $l"
      "            }"
      "            if {[regexp {^[.[:alpha:]][^ ,\\\"\\'\\[\\]\\\\;]*$} $l]} {"
      "                return $l"
      "            }"
      "            set result \\\""
      "            append result\\"
      "                [string map [list \\\" \\\\\\\" \\\\ \\\\\\\\] $l]"
      "            append result \\\""
      ""
      "        }"
      "        default {"
      "            set result {}"
      "            foreach el $l {"
      "                append result \" \" [tclListToScmList $el]"
      "            }"
      "            set result [string range $result 1 end]"
      "            return \"($result)\""
      "        }"
      "    }"
      "}"
      ""
      "proc evalCmdFromScm {cmd {properly 0}} {"
      "    if {[catch {"
      "        set result [uplevel \\#0 $cmd]"
      "    } err]} {"
      "        puts \"(error \\\"[string map [list \\\\ \\\\\\\\ \\\" \\\\\\\"] $err]\\\")\""
      "    } elseif $properly {"
      "        puts \"(return [tclListToScmList $result])\""
      "    } else {"
      "        puts \"(return \\\"[string map [list \\\\ \\\\\\\\ \\\" \\\\\\\"] $result]\\\")\""
      "    }"
      "    flush stdout"
      "}")
    nl)) ) )

(define *ttk-full-widget-map* '(
  "button"
  "checkbutton"
  "radiobutton"
  "menubutton"
  "label"
  "entry"
  "frame"
  "labelframe"
  "scrollbar"
  "notebook"
  "progressbar"
  "combobox"
  "separator"
  "scale"
  "sizegrip"
  "treeview"))

(define *wish-false-values* `(0 "0" '0 "false" 'false))

(cond-expand
  (chicken
    (define *wish-tostring-map* '(
      ("\\" . "\\\\")
      ("\"" . "\\\"")))
    ;
    (define *wish-escape-map* `(
      ,@*wish-tostring-map*
      ("[" . "\\u005b")
      ("]" . "\\]")
      ("$" . "\\u0024")
      ("{" . "\\{")
      ("}" . "\\}"))) )
  (else
    (define *wish-tostring-map* '(
      (#\\ . "\\\\")
      (#\" . "\\\"")))
    ;
    (define *wish-escape-map* `(
      ,@*wish-tostring-map*
      (#\[ . "\\u005b")
      (#\] . "\\]")
      (#\$ . "\\u0024")
      (#\{ . "\\{")
      (#\} . "\\}"))) ) )

(define *wish-exit-lag* "200")

;;

(cond-expand
  (chicken
    (define *keyword? keyword?) )
  (else
    (define *use-keywords?*
      (or (not (symbol? 'text:))
          (not (symbol? ':text))
          (string=? "text" (symbol->string 'text:))
          (string=? "text" (symbol->string ':text))))
    ;
    (define (*keyword? x)
      (and *use-keywords?* (keyword? x))) ) )

(define (run-program program)
  ;must not 2>&1 since doesn't match tcl results
  (process program) )

(cond-expand
  (chicken)
  (else
    (define (string-prefix? s1 s2)
      (string=? (substring s2 0 (string-length s1)) s1)) ) )

(cond-expand
  (chicken
    #; ;UNUSED
    (define (string-char-split c s)
      (string-split s (string c) #t) )
    ;
    (define (string-space-split str)
      (string-split " " str) ) )
  (else
    (define (string-char-split c s)
      (letrec (
        (split
          (lambda (i k tmp res)
            (cond
              ((fx= i k)
                (if (null? tmp)
                  res
                  (cons tmp res)) )
              ((char=? (string-ref s i) c)
                (split (fx+ i 1) k
                  ""
                  (cons tmp res)) )
              (else
                (split (fx+ i 1) k
                  (string-append tmp (string (string-ref s i)))
                  res) ) ) ) ) )
        (reverse (split 0 (string-length s) "" '()))))
    ;
    (define (string-space-split str)
      (string-char-split #\space str) ) ) )

(cond-expand
  (chicken
    (define gen-symbol gensym) )
  (else
    (define gen-symbol
      (let ((counter 0))
        (lambda ()
          (let ((sym (string-append "g" (number->string counter))))
            (set! counter (+ counter 1))
            (string->symbol sym))))) ) )

(cond-expand
  (chicken
    (define (report-error x)
      (error 'pstk x) ) )
  (else
    (define (report-error x)
      (newline)
      (display x)
      (newline)) ) )

(define (report-internal-error cmd . strs)
  (report-error
    (apply string-append
      "from Tcl/Tk" nl
      (if cmd (string-append " " cmd nl) "")
      " -->"
      (map (lambda (s) (string-append " " s)) strs))) )

(define (option? x)
  (or
    (*keyword? x)
    (and
      (symbol? x)
      (let* (
        (s (symbol->string x))
        (n (string-length s)) )
        (char=? #\: (string-ref s (fx- n 1)))))) )

(define (make-option-string x)
  (if (*keyword? x)
    (string-append " -" (keyword->string x))
    (let (
      (s (symbol->string x)) )
      (string-append " -" (substring s 0 (fx- (string-length s) 1))))) )

(cond-expand
  (chicken
    (define (form->string x)
      (if (pair? x)
        (string-append "(" (string-concatenate (improper-list->string x #t)) ")")
        (->string x)) ) )
  (else
    (define (form->string x)
      (cond
        ((eq? #t x) "#t")
        ((eq? #f x) "#f")
        ((number? x) (number->string x))
        ((symbol? x) (symbol->string x))
        ((string? x) x)
        ((null? x) "()")
        ((pair? x)
          (string-append "(" (string-concatenate (improper-list->string x #t)) ")"))
        ((eof-object? x) "#<eof>")
        (else "#<other>"))) ) )

(define (improper-list->string a 1st?)
  (cond
    ((pair? a)
      (cons
        (string-append (if 1st? "" " ") (form->string (car a)))
        (improper-list->string (cdr a) #f)))
    ((null? a)
      '())
    (else
      (list (string-append " . " (form->string a))))) )

;note that map characters are always in the 00..7f code-range & UTF8 are 80..
(cond-expand
  (chicken)
  (else
    (define (string-translate* s map)
      (letrec (
        (s-prepend (lambda (s1 s2)
          (cond
            ((null? s1)
              s2)
            (else
              (s-prepend (cdr s1) (cons (car s1) s2))))))
        (s-xlate (lambda (s r)
          (cond
            ((null? s)
              (reverse r))
            (else
              (let ((n (assv (car s) map)))
                (cond
                  (n
                    (s-xlate (cdr s) (s-prepend (string->list (cdr n)) r)))
                  (else
                    (s-xlate (cdr s) (cons (car s) r))))))))) )
         (list->string
           (s-xlate (string->list s) '())))) ) )

(define (wish-xstring-escape x)
  (string-translate* x *wish-escape-map*) )

(define (wish-string-escape x)
  (string-translate* x *wish-tostring-map*) )

(cond-expand
  (chicken
    ;whitespace, not just " "
    (define string-trim-left string-trim) )
  (else
    (define (string-trim-left str)
      (cond
        ((string-null? str)
          "")
        ((string-prefix? str " ")
          (string-trim-left (substring str 1 (string-length str))))
        (else
          str))) ) )

(define (get-property key args . thunk)
  (cond
    ((null? args)
      (cond
        ((null? thunk)
          #f)
        (else
          ((car thunk)))) )
    ((eq? key (car args))
      (cond
        ((pair? (cdr args))
          (cadr args) )
        (else
          (report-error (list 'get-property key args)) ) ) )
    ((or (not (pair? (cdr args))) (not (pair? (cddr args))))
      (report-error (list 'get-property key args)) )
    (else
      (apply get-property key (cddr args) thunk) ) ) )

(define (tcl-true? obj)
  (not (memv obj *wish-false-values*)) )

(define flush-output-port flush-output)

(define (error-arglist args)
  (if (null? args)
    ""
    (string-append
      ": " (string-intersperse (map form->string args) " "))) )

(define (error-unstarted-wish . args)
  (report-error
    (string-append "needs tk-start'ing'" (error-arglist args))) )
;;

(define-constant TOTAL_KEYWORDS 54)

(define-values (
  tk
  ;
  tk-eval
  tk-id->widget
  tk-var
  tk-get-var
  tk-set-var!
  tk-start
  tk-end
  tk-dispatch-event
  tk-event-loop
  tk-wait-for-window
  tk-wait-until-visible
  tk-with-lock
  ;
  tk/after
  tk/bell
  tk/update
  tk/clipboard
  tk/bgerror
  tk/bind
  tk/bindtags
  tk/destroy
  tk/event
  tk/focus
  tk/grab
  tk/grid
  tk/image
  tk/lower
  tk/option
  tk/pack
  tk/place
  tk/raise
  tk/selection
  tk/choose-color
  tk/choose-directory
  tk/dialog
  tk/get-open-file
  tk/get-save-file
  tk/message-box
  tk/focus-follows-mouse
  tk/focus-next
  tk/focus-prev
  tk/popup
  tk/appname
  tk/caret
  tk/scaling
  tk/useinputmethods
  tk/wait
  tk/windowingsystem
  tk/wm
  tk/winfo
  ;
  ttk/available-themes
  ttk/set-theme
  ttk/style
  ttk-map-widgets)
  ;
  (apply values (iota TOTAL_KEYWORDS)))

(define (make-pstk #!key (start-program (pstk-start-program)))
  (let (
    ;
    (wish-start-program start-program)
    ;
    (wish-input-port #f)
    (wish-output-port #f)
    (wish-pid #f)
    (tk-is-running #f)
    (tk-ids+widgets '())
    (tk-widgets '())
    (commands-invoked-by-tk '())
    (inverse-commands-invoked-by-tk '())
    (in-callback #f)
    (callback-mutex #t)
    (ttk-widget-map '())
    (tk-init-string *wish-initrc*)
    ;
    (tk-proc #f)
    ;
    (tk/wait-proc #f)
    (tk/wm-proc #f)
    (tk/winfo-proc #f)
    ;
    (op-map (make-vector TOTAL_KEYWORDS #f)) )
    ;
    (letrec (
      ;
      (wished-input-port
        (lambda ()
          (if wish-input-port
            wish-input-port
            (error-unstarted-wish))) )
      ;
      (wished-output-port
        (lambda ()
          (if wish-output-port
            wish-output-port
            (error-unstarted-wish))) )
      ;
      (flush-wish
        (lambda ()
          (flush-output-port (wished-input-port)) ) )
      ;
      (widget?
        (lambda (x)
          (and (memq x tk-widgets) #t) ) )
      ;
      (call-by-key
        (lambda (key resultvar . args)
          (cond
            ((and in-callback (pair? callback-mutex))
              #f)
            (else
              (set! in-callback (cons #t in-callback))
              (let* (
                (cmd
                  (get-property key commands-invoked-by-tk))
                (result
                  (apply cmd args))
                (str
                  (string-trim-left (scheme-arglist->tk-argstring (list result)))) )
                (set-var! resultvar str)
                (set! in-callback (cdr in-callback))
                result ) ) ) ) )
      ;
      (widget-name
        (lambda (x)
          (let (
            (name (form->string x)) )
            (cond
              ((member name ttk-widget-map)
                (string-append "ttk::" name))
              (else
                name ) ) ) ) )
      ;
      (make-widget-by-id
        (lambda (type id . options)
          (let (
            (result
              (lambda (command . args)
                (case command
                  ((get-id)
                    id )
                  ((create-widget)
                    (let* (
                      (widget-type (widget-name (car args)))
                      (id-prefix (if (string=? id ".") "" id))
                      (id-suffix (form->string (gen-symbol)))
                      (new-id (string-append id-prefix "." id-suffix))
                      (options (cdr args)) )
                      (eval-wish
                        widget-type " " new-id
                        (scheme-arglist->tk-argstring options))
                      (apply make-widget-by-id (append (list widget-type new-id) options))) )
                  ((configure)
                    (cond
                      ((null? args)
                        (eval-wish id " " (form->string command)) )
                      ((null? (cdr args))
                        (eval-wish
                          id " " (form->string command)
                          (scheme-arglist->tk-argstring args)) )
                      (else
                        (eval-wish
                          id " " (form->string command)
                          (scheme-arglist->tk-argstring args))
                        (do ((args args (cddr args)))
                            ((null? args) '())
                          (let (
                            (key (car args))
                            (val (cadr args)) )
                            (cond
                              ((null? options)
                                (set! options (list key val)) )
                              ((not (memq key options))
                                (set! options (cons key (cons val options))) )
                              (else
                                (set-car! (cdr (memq key options)) val) ) ) ) ) ) ) )
                  ((cget)
                    (let (
                      (key (car args)) )
                      (get-property
                        key
                        options
                        (lambda ()
                          (eval-wish
                            id " cget"
                            (scheme-arglist->tk-argstring args)))) ) )
                  ((call exec)
                    (eval-wish
                      (string-trim-left (scheme-arglist->tk-argstring args))) )
                  (else
                    (eval-wish
                      id " " (form->string command)
                      (scheme-arglist->tk-argstring args)) ) ) ) ) )
            ;
            (set! tk-widgets (cons result tk-widgets))
            (set! tk-ids+widgets  (cons (string->symbol id) (cons result tk-ids+widgets)))
            result) ) )
      ;
      (scheme-arg->tk-arg
        (lambda (x)
          (cond
            ((eq? x #f) " 0")
            ((eq? x #t) " 1")
            ((eq? x '()) " {}")
            ((option? x) (make-option-string x))
            ((widget? x) (string-append " " (x 'get-id)))
            ((and (pair? x) (procedure? (car x)))
              (let* (
                (lambda-term (car x))
                (rest (cdr x))
                (l
                  (memq lambda-term inverse-commands-invoked-by-tk))
                (keystr
                  (if l (form->string (cadr l)) (symbol->string (gen-symbol)))) )
                (if (not l)
                  (let (
                    (key (string->symbol keystr)) )
                    (set! inverse-commands-invoked-by-tk
                      (cons lambda-term (cons key inverse-commands-invoked-by-tk)))
                    (set! commands-invoked-by-tk
                      (cons key (cons lambda-term commands-invoked-by-tk)))))
                (string-append
                  " {callToScm " keystr (scheme-arglist->tk-argstring rest) "}") ) )
            ((procedure? x)
              (scheme-arglist->tk-argstring `((,x))))
            ((proper-list? x)
              (cond
                ((eq? (car x) '+)
                  (let (
                    (result (string-trim-left (scheme-arglist->tk-argstring (cdr x)))) )
                  (cond
                    ((string-null? result)
                      (string-append " +"))
                    ((string-prefix? "{" result)
                      (string-append
                        " {+ " (substring result 1 (string-length result))))
                    (else
                      (string-append " +" result)))))
                ((and
                  (fx= 3 (length x))
                  (equal? '@ (car x))
                  (number? (cadr x))
                  (number? (caddr x)))
                  (string-append
                   "@" (number->string (cadr x)) "," (number->string (caddr x))))
                (else
                  (string-append
                    " {" (string-trim-left (scheme-arglist->tk-argstring x)) "}"))))
            ((pair? x)
              (string-append
                " " (form->string (car x)) "." (form->string (cdr x))))
            ((string? x)
              (if (string->number x)
                (string-append " " x)
                (string-append
                  " \"" (wish-xstring-escape x) "\"")))
            (else
              (string-append " " (form->string x)))) ) )
      ;
      (scheme-arglist->tk-argstring
        (lambda (args)
          (string-concatenate (map scheme-arg->tk-arg args)) ) )
      ;
      (make-wish-func
        (lambda (tkname)
          (let (
            (name (form->string tkname)) )
            (lambda args
              (eval-wish name (scheme-arglist->tk-argstring args)))) ) )
      ;
      (read-wish
        (lambda ()
          (let (
            (term (read (wished-output-port))) )
            (when *wish-debug-output?*
              (display "wish->scheme: ")
              (write (if (eof-object? term) '#!eof term))
              (newline) )
            term ) ) )
      ;
      (wish
        (lambda arguments
          (for-each
            (lambda (argument)
              (when *wish-debug-input?*
                (display "scheme->wish: ")
                (display argument)
                (newline) )
              (display argument (wished-input-port))
              (newline (wished-input-port))
              (flush-wish) )
            arguments) ) )
      ;
      (start-wish
        (lambda ()
          (let-values (
            ((in out pid) (run-program wish-start-program)) )
            (set! wish-input-port out)
            (set! wish-output-port in)
            (set! wish-pid pid) ) ) )
      ;
      (eval-wish
        (lambda args
          (let (
            ;
            (cmd
              (if (and (pair? args) (null? (cdr args)))
                (car args)
                (string-concatenate args))) )
            ;
            (wish
              (string-append
                "evalCmdFromScm"
                " \"" (wish-string-escape cmd) "\""))
            ;
            (let again ((result (read-wish)))
              (cond
                ;
                ((eof-object? result)
                  (report-error "Unexpected EOF") )
                ;
                ((not (pair? result))
                  ;clears input line
                  (report-internal-error
                    #f
                    (form->string result)
                    (read-line (wished-output-port))))
                ;
                ((eq? (car result) 'return)
                  (cadr result))
                ;
                ((eq? (car result) 'call)
                  (apply call-by-key (cdr result))
                  (again (read-wish)))
                ;
                ((eq? (car result) 'error)
                  (report-internal-error cmd (cadr result)))
                ;
                (else
                  (report-error result)))) ) ) )
      ;
      (id->widget
        (lambda (id)
          (get-property
            (string->symbol (form->string id))
            tk-ids+widgets
            (lambda ()
              (and
                (tcl-true? (tk/winfo-proc 'exists id))
                (make-widget-by-id (tk/winfo-proc 'class id) (form->string id))))) ) )
      ;
      (var
        (lambda (varname)
          (set-var! varname "")
          (string-append
            "::scmVar(" (form->string varname) ")") ) )
      ;
      (get-var
        (lambda (varname)
          (eval-wish "set ::scmVar(" (form->string varname) ")") ) )
      ;
      (set-var!
        (lambda (varname value)
          (eval-wish
            "set ::scmVar(" (form->string varname) ")"
            " {" (form->string value) "}") ) )
      ;
      (start
        (lambda args ;optional argument allows user to input name of wish program
          (when (and (pair? args) (null? (cdr args)))
            (set! wish-start-program (car args)) )
          (start-wish)
          (wish tk-init-string)
          (set! tk-ids+widgets '())
          (set! tk-widgets '())
          (set! in-callback #f)
          (set! tk-proc (make-widget-by-id 'toplevel "." 'class: 'Wish))
          (vector-set! op-map tk tk-proc)
          (set! commands-invoked-by-tk '())
          (set! inverse-commands-invoked-by-tk '())
          (tk/wm-proc 'protocol tk-proc 'WM_DELETE_WINDOW end-tk) ) )
      ;
      (end-tk
        (lambda ()
          (set! tk-is-running #f)
          (wish
            (string-append
              "after " *wish-exit-lag* " exit")) ) )
      ;
      (dispatch-event
        (lambda ()
          (let (
            (tk-statement (read-wish)) )
            (when (and (proper-list? tk-statement) (eq? (car tk-statement) 'call))
              (apply call-by-key (cdr tk-statement))) ) ) )
      ;
      (loop
        (lambda ()
          (cond
            ((not tk-is-running)
              (when wish-output-port
                (tk/wm-proc 'protocol tk-proc 'WM_DELETE_WINDOW '())) )
            (else
              (dispatch-event)
              (loop) ) ) ) )
      ;
      (event-loop
        (lambda ()
          (set! tk-is-running #t)
          (loop) ) )
      ;
      (map-ttk-widgets
        (lambda (x)
          (cond
            ((eq? x 'all)
              (set! ttk-widget-map *ttk-full-widget-map*))
            ((eq? x 'none)
              (set! ttk-widget-map '()))
            ((pair? x)
              (set! ttk-widget-map (map form->string x)))
            (else
              (report-error
                (string-append
                  "Argument to TTK-MAP-WIDGETS must be "
                  "ALL, NONE or a list of widget types: "
                  (form->string x))))) ) )
      ;
      (ttk-available-themes
        (lambda ()
         (string-space-split (eval-wish "ttk::style theme names")) ) )
      ;
      (do-wait-for-window
        (lambda (w)
          (dispatch-event)
          (cond
            ((equal? (tk/winfo-proc 'exists w) "0")
              '() )
            (else
              (do-wait-for-window w) ) ) ) )
      ;
      (wait-for-window
        (lambda (w)
          (let (
            (outer-allow callback-mutex) )
            (set! callback-mutex #t)
            (do-wait-for-window w)
            (set! callback-mutex outer-allow)) ) )
      ;
      (wait-until-visible
        (lambda (w)
          (tk/wait-proc 'visibility w) ) )
      ;
      (lock!
        (lambda ()
          (set! callback-mutex (cons callback-mutex #t)) ) )
      ;
      (unlock!
        (lambda ()
          (if (pair? callback-mutex)
            (set! callback-mutex (cdr callback-mutex)) ) ) )
      ;
      (with-lock
        (lambda (thunk)
          (lock!)
          (thunk)
          (unlock!) ) ) )
      ;
      (set! tk/wait-proc (lambda _ (make-wish-func 'tkwait)))
      (set! tk/wm-proc (make-wish-func 'wm))
      (set! tk/winfo-proc (make-wish-func 'winfo))
      ;
      (vector-set! op-map tk-eval eval-wish)
      (vector-set! op-map tk-id->widget id->widget)
      (vector-set! op-map tk-var var)
      (vector-set! op-map tk-get-var get-var)
      (vector-set! op-map tk-set-var! set-var!)
      (vector-set! op-map tk-start start)
      (vector-set! op-map tk-end end-tk)
      (vector-set! op-map tk-dispatch-event dispatch-event)
      (vector-set! op-map tk-event-loop event-loop)
      (vector-set! op-map tk-wait-for-window wait-for-window)
      (vector-set! op-map tk-wait-until-visible wait-until-visible)
      (vector-set! op-map tk-with-lock with-lock)
      ;
      (vector-set! op-map tk/after (make-wish-func 'after))
      (vector-set! op-map tk/bell (make-wish-func 'bell))
      (vector-set! op-map tk/update (make-wish-func 'update))
      (vector-set! op-map tk/clipboard (make-wish-func 'clipboard))
      (vector-set! op-map tk/bgerror (make-wish-func 'bgerror))
      (vector-set! op-map tk/bind (make-wish-func 'bind))
      (vector-set! op-map tk/bindtags (make-wish-func 'bindtags))
      (vector-set! op-map tk/destroy (make-wish-func 'destroy))
      (vector-set! op-map tk/event (make-wish-func 'event))
      (vector-set! op-map tk/focus (make-wish-func 'focus))
      (vector-set! op-map tk/grab (make-wish-func 'grab))
      (vector-set! op-map tk/grid (make-wish-func 'grid))
      (vector-set! op-map tk/image (make-wish-func 'image))
      (vector-set! op-map tk/lower (make-wish-func 'lower))
      (vector-set! op-map tk/option (make-wish-func 'option))
      (vector-set! op-map tk/pack (make-wish-func 'pack))
      (vector-set! op-map tk/place (make-wish-func 'place))
      (vector-set! op-map tk/raise (make-wish-func 'raise))
      (vector-set! op-map tk/selection (make-wish-func 'selection))
      (vector-set! op-map tk/choose-color (make-wish-func "tk_chooseColor"))
      (vector-set! op-map tk/choose-directory (make-wish-func "tk_chooseDirectory"))
      (vector-set! op-map tk/dialog (make-wish-func "tk_dialog"))
      (vector-set! op-map tk/get-open-file (make-wish-func "tk_getOpenFile"))
      (vector-set! op-map tk/get-save-file (make-wish-func "tk_getSaveFile"))
      (vector-set! op-map tk/message-box (make-wish-func "tk_messageBox"))
      (vector-set! op-map tk/focus-follows-mouse (make-wish-func "tk_focusFollowsMouse"))
      (vector-set! op-map tk/focus-next (make-wish-func "tk_focusNext"))
      (vector-set! op-map tk/focus-prev (make-wish-func "tk_focusPrev"))
      (vector-set! op-map tk/popup (make-wish-func "tk_popup"))
      (vector-set! op-map tk/appname (make-wish-func "tk appname"))
      (vector-set! op-map tk/caret (make-wish-func "tk caret"))
      (vector-set! op-map tk/scaling (make-wish-func "tk scaling"))
      (vector-set! op-map tk/useinputmethods (make-wish-func "tk useinputmethods"))
      (vector-set! op-map tk/wait tk/wait-proc)
      (vector-set! op-map tk/windowingsystem (make-wish-func "tk windowingsystem"))
      (vector-set! op-map tk/wm tk/wm-proc)
      (vector-set! op-map tk/winfo tk/winfo-proc)
      ;
      (vector-set! op-map ttk/available-themes ttk-available-themes)
      (vector-set! op-map ttk/set-theme (make-wish-func "ttk::style theme use"))
      (vector-set! op-map ttk/style (make-wish-func "ttk::style"))
      (vector-set! op-map ttk-map-widgets map-ttk-widgets)
      ;
      (lambda (op)
        (if (and (fixnum? op) (fx<= 0 op) (fx< op TOTAL_KEYWORDS))
          (vector-ref op-map op)
          (signal-bounds-error 'pstk op) ) ) ) ) )

;;

(define pstk-start-program (make-parameter "tclsh" (lambda (x)
  (if (string? x)
    x
    (begin
      (warning 'pstk-start-program "invalid pstk command" x))))))

;;

(define (pstk-start $)
  (($ tk-start))
  (values ($ tk) (lambda (op . args) (apply ($ op) args))) )

;;

(define (pstk . init-args)
  (pstk-start (apply make-pstk init-args)) )

) ;module pstk-make
