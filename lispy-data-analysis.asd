(defsystem "lispy-data-analysis"
  :version "0.1.0"
  :author "Yacin Nadji <ynadji@gmail.com>"
  :license "MIT"
  :description "Remote REPL tool for data analysis with DuckDB and Vega-Lite"
  :depends-on ("duckdb"
               "alexandria"
               "com.inuoe.jzon"
               "swank"
               "bordeaux-threads"
               "clingon")
  :components ((:file "package")
               (:module "src"
                :components
                ((:file "database" :depends-on ())
                 (:file "visualization" :depends-on ())
                 (:file "swank-server" :depends-on ())
                 (:file "cli" :depends-on ("database" "visualization" "swank-server")))
                :depends-on ("package")))
  :build-operation "program-op"
  :build-pathname "bin/lda"
  :entry-point "lispy-data-analysis/cli:main")
