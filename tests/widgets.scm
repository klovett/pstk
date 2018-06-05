;;;;

(use pstk)
(use pstk-utils)

;; PS-TK example: display frame and some varied widgets

(tk-start)
(ttk-map-widgets 'all) ;make sure we are using tile widget set
(ttk/set-theme "clam") ;(list-ref (ttk/available-themes) 0))

(tk/wm 'title tk "PS-Tk Example: Different Widgets")
(tk 'configure height: 230 width: 680)

;;-- note, untiled tk widgets like to store their values in variables
;;         (there seems no way to query a checkbutton for its state)
;;   This is done using tk-var and tk-get-var

;;create a checkbutton, and associated variable to hold its state
(tk-var 'cb-value)
(tk/place
  (tk 'create-widget 'checkbutton text: "Check me"
    variable: (tk-var 'cb-value))
  x: 50 y: 10 width: 100 height: 20)

;;create a set of radiobuttons, and associated variable/group
(tk-var 'radio-value)
(tk/place
  (tk 'create-widget 'radiobutton text: "Blue"
    variable: (tk-var 'radio-value)
    value: "Blue")
  x: 200 y: 10 width: 100 height: 20)
(tk/place
  (tk 'create-widget 'radiobutton text: "Green"
    variable: (tk-var 'radio-value)
    value: "Green")
  x: 200 y: 50 width: 100 height: 20)
(tk/place
  (tk 'create-widget 'radiobutton text: "Red"
    variable: (tk-var 'radio-value)
    value: "Red")
  x: 200 y: 90 width: 100 height: 20)
(tk-set-var! 'radio-value "Blue") ;set an initial value for radio buttons

;;create a spinbox
(tk-var 'spin-value)
(tk/place
  (tk 'create-widget 'label text: "Spin: ")
  x: 10 y: 120 width: 30 height: 20)
(tk/place
  (tk 'create-widget 'spinbox from: 1 to: 10 textvariable: (tk-var 'spin-value))
  x: 50 y: 120 width: 30 height: 30)

;;create a drop-down combination list and a tree view
;;-- use of tiled widgets allows us to query a widget instance for its current state
(let (
  (combobox (tk 'create-widget 'combobox values: "oranges apples pears" state: 'readonly))
  (treeview (tk 'create-widget 'treeview columns: '("col1" "col2" "col3")))
  (hsb (tk 'create-widget 'scrollbar orient: 'horizontal))
  (vsb (tk 'create-widget 'scrollbar orient: 'vertical)) )
  ;place combobox plus label
  (tk/place (tk 'create-widget 'label text: "List: ") x: 10 y: 60 width: 30 height: 20)
  (tk/place combobox x: 50 y: 60 width: 100 height: 20)
  ;associate scrollbars and treeview
  (hsb 'configure command: (list treeview 'xview))
  (vsb 'configure command: (list treeview 'yview))
  (treeview 'configure xscrollcommand: `(,hsb set))
  (treeview 'configure yscrollcommand: `(,vsb set))
  ;set up columns in tree view
  (tk-doto treeview
    (column "col1" width: 70)
    (heading "col1" text: "Col 1")
    (column "col2" width: 70)
    (heading "col2" text: "Col 2")
    (column "col3" width: 60)
    (heading "col3" text: "Col 3") )
  ;insert items into tree view
  (tk-doto treeview
    (insert "" 'end id: "item1" text: "item 1" values: "a b 1")
    (insert "" 'end id: "subtree1" text: "item 2" values: "c d 2")
    (insert "" 'end id: "subtree2" text: "item 3" values: "e f 3")
    (insert "subtree1" 'end text: "item 4" values: "g h 4")
    (insert "subtree1" 'end text: "item 5" values: "i j 5")
    (insert "subtree2" 'end text: "item 6" values: "k l 6")
    (insert "subtree2" 'end text: "item 7" values: "m n 7")
    (insert "subtree2" 'end text: "item 8" values: "o p 8") )
  ;place tree view and scroll bar
  (tk-with tk/place
    (treeview x: 350 y: 10 width: 300 height: 100)
    (hsb x: 350 y: 110 width: 300 height: 20)
    (vsb x: 650 y: 10 width: 20 height: 100) )
  ;create a button to dump values of all widgets to stdout
  (tk/place
    (tk 'create-widget 'button text: "Show values"
      command:
      (lambda ()
        (display "Check button: ") (display (tk-get-var 'cb-value)) (newline)
        (display "Radio button: ") (display (tk-get-var 'radio-value)) (newline)
        (display "    Combobox: ") (display (combobox 'get)) (newline)
        (display "    Spin box: ") (display (tk-get-var 'spin-value)) (newline)
        (display "   Tree view: ") (display (treeview 'selection)) (newline)))
    x: 200 y: 150 width: 90 height: 30)
  ;& one to exit
  (tk/place
    (tk 'create-widget 'button
      text: "Cancel"
      command: (lambda () (tk-end)))
    x: 200 y: 185 width: 90 height: 30) )

(tk-event-loop)

