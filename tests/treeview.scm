;;;;

(use pstk-make)
(use pstk-utils)

;; PS-TK example: display a treeview

(define-values (tk $) (pstk)) ;tk-start'ed

($ ttk-map-widgets 'all) ;make sure we are using tile widget set

($ tk/wm 'title tk "PS-Tk Example: TreeView")
(tk 'configure height: 230 width: 350)

;create a tree view within scroll bars
(define treeview
  (let (
    (treeview (tk 'create-widget 'treeview columns: '("col1" "col2" "col3")))
    (hsb (tk 'create-widget 'scrollbar orient: 'horizontal))
    (vsb (tk 'create-widget 'scrollbar orient: 'vertical)) )
    ;associate scrollbars and treeview
    (hsb 'configure command: `(,treeview xview))
    (vsb 'configure command: `(,treeview yview))
    (treeview 'configure
      xscrollcommand: `(,hsb set)
      yscrollcommand: `(,vsb set))
    ;set up columns in tree view
    (tk-doto treeview
      (column "col1" width: 70)
      (heading "col1" text: "Col 1")
      (column "col2" width: 70)
      (heading "col2" text: "Col 2")
      (column "col3" width: 70)
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
    (tk-with ($ tk/grid)
      (treeview column: 0 row: 0 sticky: 'nesw)
      (hsb column: 0 row: 1 sticky: 'we)
      (vsb column: 1 row: 0 sticky: 'ns) )
    ;ensure grid fills the frame
    (tk-doto ($ tk/grid)
      (columnconfigure tk 0 weight: 1)
      (rowconfigure tk 0 weight: 1) )
    ;
    treeview ) )

;create a label and button to show selection
(let* (
  (label (tk 'create-widget 'label))
  (show
    (tk 'create-widget 'button
      text: "Show item"
      command: (lambda () (label 'configure text: (treeview 'selection)))))
  (cancel
    (tk 'create-widget 'button
      text: "Cancel"
      command: (lambda () ($ tk-end)))) )
  (tk-with ($ tk/grid)
    (label column: 0 row: 2 pady: 5)
    (show column: 0 row: 3 pady: 5)
    (cancel column: 0 row: 4 pady: 5) ) )

($ tk-event-loop)

