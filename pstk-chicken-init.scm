;;;; pstk-chicken-init.scm
;;;; Kon Lovett, May '18

(define WISH-INITRC #<<EOS
  package require Tk
  if {[package version tile] != ""} {
      package require tile
  }

  namespace eval AutoName {
      variable c 0
      proc autoName {{result \#\#}} {
          variable c
          append result [incr c]
      }
      namespace export *
  }

  namespace import AutoName::*

  proc callToScm {callKey args} {
      global scmVar
      set resultKey [autoName]
      puts "(call $callKey \"$resultKey\" $args)"
      flush stdout
      vwait scmVar($resultKey)
      set result $scmVar($resultKey)
      unset scmVar($resultKey)
      set result
  }

  proc tclListToScmList {l} {
      switch [llength $l] {
          0 {
              return ()
          }
          1 {
              if {[string range $l 0 0] eq "\#"} {
                  return $l
              }
              if {[regexp {^[0-9]+$} $l]} {
                  return $l
              }
              if {[regexp {^[.[:alpha:]][^ ,\"\'\[\]\\;]*$} $l]} {
                  return $l
              }
              set result \"
              append result\
                  [string map [list \" \\\" \\ \\\\] $l]
              append result \"

          }
          default {
              set result {}
              foreach el $l {
                  append result " " [tclListToScmList $el]
              }
              set result [string range $result 1 end]
              return "($result)"
          }
      }
  }

  proc evalCmdFromScm {cmd {properly 0}} {
      if {[catch {
          set result [uplevel \#0 $cmd]
      } err]} {
          puts "(error \"[string map [list \\ \\\\ \" \\\"] $err]\")"
      } elseif $properly {
          puts "(return [tclListToScmList $result])"
      } else {
          puts "(return \"[string map [list \\ \\\\ \" \\\"] $result]\")"
      }
      flush stdout
  }
EOS
)
