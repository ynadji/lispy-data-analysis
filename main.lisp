(ql:quickload :duckdb)
(ql:quickload :alexandria)

(defpackage :lispy-data-analysis
  (:use :cl)
  (:nicknames :lda)
  (:local-nicknames (:db :duckdb)
                    (:ax :alexandria)))

(in-package :lispy-data-analysis)

(db:initialize-default-connection :allow-unsigned-extensions t)
