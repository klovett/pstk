;;;; pstk.scm
;;;; (see below)
;;;; Kon Lovett, May '18

(module pstk

(export
  ;
  tk
  ;
  tk-dispatch-event
  tk-end
  tk-eval
  tk-event-loop
  tk-get-var
  tk-id->widget
  tk-set-var!
  tk-start
  tk-var
  tk-wait-for-window
  tk-wait-until-visible
  tk-with-lock
  ;
  tk/after
  tk/appname
  tk/bell
  tk/bgerror
  tk/bind
  tk/bindtags
  tk/caret
  tk/choose-color
  tk/choose-directory
  tk/clipboard
  tk/destroy
  tk/dialog
  tk/event
  tk/focus
  tk/focus-follows-mouse
  tk/focus-next
  tk/focus-prev
  tk/get-open-file
  tk/get-save-file
  tk/grab
  tk/grid
  tk/image
  tk/lower
  tk/message-box
  tk/option
  tk/pack
  tk/place
  tk/popup
  tk/raise
  tk/scaling
  tk/selection
  tk/update
  tk/useinputmethods
  tk/wait
  tk/windowingsystem
  tk/winfo
  tk/wm
  ;
  ttk-map-widgets
  ttk/available-themes
  ttk/set-theme
  ttk/style)

(import scheme chicken)
(use (prefix pstk-make x:))

;;

(define $ (x:make-pstk))

(define tk)

(define (tk-start . args)
  (apply ($ x:tk-start) args)
  (set! tk ($ x:tk)) )

(define tk-dispatch-event ($ x:tk-dispatch-event))
(define tk-end ($ x:tk-end))
(define tk-eval ($ x:tk-eval))
(define tk-event-loop ($ x:tk-event-loop))
(define tk-get-var ($ x:tk-get-var))
(define tk-id->widget ($ x:tk-id->widget))
(define tk-set-var! ($ x:tk-set-var!))
(define tk-var ($ x:tk-var))
(define tk-wait-for-window ($ x:tk-wait-for-window))
(define tk-wait-until-visible ($ x:tk-wait-until-visible))
(define tk-with-lock ($ x:tk-with-lock))
;
(define tk/after ($ x:tk/after))
(define tk/appname ($ x:tk/appname))
(define tk/bell ($ x:tk/bell))
(define tk/bgerror ($ x:tk/bgerror))
(define tk/bind ($ x:tk/bind))
(define tk/bindtags ($ x:tk/bindtags))
(define tk/caret ($ x:tk/caret))
(define tk/choose-color ($ x:tk/choose-color))
(define tk/choose-directory ($ x:tk/choose-directory))
(define tk/clipboard ($ x:tk/clipboard))
(define tk/destroy ($ x:tk/destroy))
(define tk/dialog ($ x:tk/dialog))
(define tk/event ($ x:tk/event))
(define tk/focus ($ x:tk/focus))
(define tk/focus-follows-mouse ($ x:tk/focus-follows-mouse))
(define tk/focus-next ($ x:tk/focus-next))
(define tk/focus-prev ($ x:tk/focus-prev))
(define tk/get-open-file ($ x:tk/get-open-file))
(define tk/get-save-file ($ x:tk/get-save-file))
(define tk/grab ($ x:tk/grab))
(define tk/grid ($ x:tk/grid))
(define tk/image ($ x:tk/image))
(define tk/lower ($ x:tk/lower))
(define tk/message-box ($ x:tk/message-box))
(define tk/option ($ x:tk/option))
(define tk/pack ($ x:tk/pack))
(define tk/place ($ x:tk/place))
(define tk/popup ($ x:tk/popup))
(define tk/raise ($ x:tk/raise))
(define tk/scaling ($ x:tk/scaling))
(define tk/selection ($ x:tk/selection))
(define tk/update ($ x:tk/update))
(define tk/useinputmethods ($ x:tk/useinputmethods))
(define tk/wait ($ x:tk/wait))
(define tk/windowingsystem ($ x:tk/windowingsystem))
(define tk/winfo ($ x:tk/winfo))
(define tk/wm ($ x:tk/wm))
;
(define ttk-map-widgets ($ x:ttk-map-widgets))
(define ttk/available-themes ($ x:ttk/available-themes))
(define ttk/set-theme ($ x:ttk/set-theme))
(define ttk/style ($ x:ttk/style))

) ;module pstk

; PS/Tk -- A Portable Scheme Interface to the Tk GUI Toolkit
; Copyright (C) 2008 Kenneth A Dickey
; Copyright (C) 2006-2008 Nils M Holm
; Copyright (C) 2004 Wolf-Dieter Busch
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions
; are met:
; 1. Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright
;    notice, this list of conditions and the following disclaimer in the
;    documentation and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
; SUCH DAMAGE.
;
; PS/Tk is based on Chicken/Tk by Wolf-Dieter Busch (2004):
; http://wolf-dieter-busch.de/html/Software/Tools/ChickenTk.htm
; which is in turn based on Scheme_wish by Sven Hartrumpf (1997, 1998):
; http://pi7.fernuni-hagen.de/hartrumpf/scheme_wish.scm
;
; These are the changes that I (Nils) made to turn Chicken/Tk into PS/Tk:
;
; - Removed all Chicken-isms except for PROCESS.
; - All PS/Tk function names begin with TK/ or TK-:
;     EVAL-WISH   --> TK-EVAL-WISH
;     GET-TK-VAR  --> TK-GET-VAR
;     SET-TK-VAR! --> TK-SET-VAR!
;     START-TK    --> TK-START
;     END-TK      --> TK-END
;     EVENT-LOOP  --> TK-EVENT-LOOP
; - Added TK-DISPATCH-EVENT.
; - Added TK-WAIT-FOR-WINDOW because TK/WAIT returned too early.
; - Removed some unused functions and variables.
; - Replaced keyword lists with property lists.
; - Removed ScrolledText compound widget.
; - Removed :WIDGET-NAME option.
; - Added a PLT Scheme version of RUN-PROGRAM.
;
; Contributions (in order of appearance):
; - Jens Axel Soegaard: PLT Scheme/Windows RUN-PROGRAM.
; - Taylor R Campbell: Scheme48 RUN-PROGRAM, portable GENSYM, and some R5RS
;   portability fixes.
; - Jeffrey T. Read: Gambit hacks (RUN-PROGRAM, keyword hack).
; - Marc Feeley: Various versions of RUN-PROGRAM (Bigloo, Gauche, Guile,
;   Kawa, Scsh, Stklos), SRFI-88 keyword auto-detection, some bug fixes.
; - David St-Hilaire: suggested catching unspecific value in form->string.
; - Ken Dickey: added Ikarus Scheme
; - Ken Dickey: added Larceny Scheme
; Thank you!
;
; Change Log:
; 2010-07-03 Optional argument to 'start' for inputting name of wish/tclsh
; 2010-06-30 Repackaged for Chicken, removing alternate run-program's.
; 2008-06-22 Added Larceny Scheme support.
; 2008-02-29 Added R6RS (Ikarus Scheme) support, added TTK/STYLE.
; 2007-06-27 Renamed source file to pstk.scm.
; 2007-06-27 Re-factored some large procedures, applied some cosmetics.
; 2007-06-26 FORM->STRING catches unspecific values now, so event handlers
;            no longer have to return specific values.
; 2007-06-26 Re-imported the following ports from the processio/v1 snowball:
;            Bigloo, Gauche, Guile, Kawa, Scsh, Stklos.
; 2007-06-26 Added auto-detection of SRFI-88 keywords.
; 2007-03-03 Removed callback mutex, because it blocked some redraw
;            operations. Use TK-WITH-LOCK to protect critical sections.
; 2007-02-03 Added Tile support: TTK-MAP-WIDGETS, TTK/AVAILABLE-THEMES,
;            TTK/SET-THEME.
; 2007-01-20 Added (Petite) Chez Scheme port.
; 2007-01-06 Fix: TK-WAIT-FOR-WINDOW requires nested callbacks.
; 2007-01-05 Added code to patch through fatal TCL messages.
; 2007-01-05 Protected call-backs by a mutex, so accidental double
;            clicks, etc cannot mess up program state.
; 2006-12-21 Made FORM->STRING accept '().
; 2006-12-18 Installing WM_DELETE_WINDOW handler in TK-START now, so it does
;            not get reset in TK-EVENT-LOOP.
; 2006-12-18 Made TK-START and TK-END return () instead of #<unspecific>
;            (which crashes FORM->STRING).
; 2006-12-12 Fixed some wrong Tcl quotation (introduced by myself).
; 2006-12-09 Added TK/BELL procedure.
; 2006-12-08 Replaced ATOM->STRING by FORM->STRING.
; 2006-12-06 Added TK-WAIT-UNTIL-VISIBLE.
; 2006-12-03 Made more variables local to outer LETREC.
; 2006-12-03 Added Gambit port and keywords hack.
; 2006-12-02 Added Scheme 48 port, portable GENSYM, R5RS fixes.
; 2006-12-02 Added PLT/Windows port.
