(defpackage :lispy-data-analysis
  (:use :cl)
  (:nicknames :lda)
  (:local-nicknames (:db :duckdb)
                    (:ax :alexandria)
                    (:jzon :com.inuoe.jzon))
  (:export
   ;; Database
   #:init-db
   #:save-state-and-die
   #:*db*

   ;; Visualization
   #:chart
   #:make-bar-chart
   #:save-chart
   #:make-vega-spec
   #:make-encoding
   #:make-mark
   #:duckdb-results->vega-data
   #:plist->hash-table
   #:vega-html-page

   ;; Swank Server
   #:start-swank-server
   #:stop-swank-server))

(defpackage :lispy-data-analysis/cli
  (:use :cl)
  (:local-nicknames (:lda :lispy-data-analysis))
  (:export #:main))
