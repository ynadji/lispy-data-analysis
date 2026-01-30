(in-package :lispy-data-analysis/cli)

;;; ---------------------------------------------------------------------------
;;; CLI Command Handlers
;;; ---------------------------------------------------------------------------

(defun server-handler (cmd)
  "Handler for the 'server' command: start swank server and keep running."
  (let ((port (clingon:getopt cmd :port))
        (host (clingon:getopt cmd :host))
        (password (clingon:getopt cmd :password))
        (daemon (clingon:getopt cmd :daemon))
        (extension-path (clingon:getopt cmd :zeek-extension)))

    ;; Initialize database
    (format t "Initializing DuckDB...~%")
    (lda:init-db :extension-path extension-path)

    ;; Start swank server in daemon mode
    (lda:start-swank-server :port port
                            :host host
                            :password password
                            :daemon daemon)))

(defun repl-handler (cmd)
  "Handler for the 'repl' command: start local REPL with initialized environment."
  (let ((extension-path (clingon:getopt cmd :zeek-extension)))

    ;; Initialize database
    (format t "Initializing DuckDB...~%")
    (lda:init-db :extension-path extension-path)

    ;; Print help message
    (format t "~%REPL ready. Available functions:~%")
    (format t "  (lda:start-swank-server)         - Start swank server for remote access~%")
    (format t "  (lda:chart results \"x\" \"y\")      - Create and display a chart~%")
    (format t "  (db:q \"SELECT ...\")                - Run SQL query~%")
    (format t "  (db:run \"CREATE TABLE ...\")        - Execute SQL statement~%")
    (format t "~%")

    ;; Drop into REPL
    (in-package :lispy-data-analysis)
    (funcall (find-symbol "REPL" :uiop))))

(defun save-handler (cmd)
  "Handler for the 'save' command: save current Lisp image."
  #+sbcl
  (let ((compression (clingon:getopt cmd :compression)))
    (format t "WARNING: This will terminate the process and overwrite the binary.~%")
    (format t "Press Ctrl-C within 3 seconds to cancel...~%")
    (sleep 3)
    (lda:save-state-and-die :compression compression))
  #-sbcl
  (progn
    (format *error-output* "ERROR: save-state-and-die is only supported on SBCL.~%")
    (uiop:quit 1)))

;;; ---------------------------------------------------------------------------
;;; CLI Command Definitions
;;; ---------------------------------------------------------------------------

(defun server-command ()
  "Define the 'server' subcommand."
  (clingon:make-command
   :name "server"
   :description "Start swank server for remote REPL access"
   :usage "server [OPTIONS]"
   :options
   (list
    (clingon:make-option
     :integer
     :description "Port to listen on"
     :short-name #\p
     :long-name "port"
     :initial-value 4005
     :key :port)

    (clingon:make-option
     :string
     :description "Host to bind to (127.0.0.1 for localhost-only, 0.0.0.0 for all interfaces)"
     :short-name #\h
     :long-name "host"
     :initial-value "127.0.0.1"
     :key :host)

    (clingon:make-option
     :string
     :description "Password for swank authentication (optional)"
     :long-name "password"
     :key :password)

    (clingon:make-option
     :boolean
     :description "Run in daemon mode (keep process alive)"
     :short-name #\d
     :long-name "daemon"
     :key :daemon)

    (clingon:make-option
     :string
     :description "Path to zeek-duckdb extension"
     :long-name "zeek-extension"
     :initial-value "~/code/zeek-duckdb/build/release/extension/zeek/zeek.duckdb_extension"
     :key :zeek-extension))
   :handler #'server-handler))

(defun repl-command ()
  "Define the 'repl' subcommand."
  (clingon:make-command
   :name "repl"
   :description "Start local REPL with initialized environment"
   :usage "repl [OPTIONS]"
   :options
   (list
    (clingon:make-option
     :string
     :description "Path to zeek-duckdb extension"
     :long-name "zeek-extension"
     :initial-value "~/code/zeek-duckdb/build/release/extension/zeek/zeek.duckdb_extension"
     :key :zeek-extension))
   :handler #'repl-handler))

(defun save-command ()
  "Define the 'save' subcommand."
  (clingon:make-command
   :name "save"
   :description "Save current Lisp image, overwriting the binary (SBCL only)"
   :usage "save [OPTIONS]"
   :options
   (list
    (clingon:make-option
     :integer
     :description "Compression level 0-9 (SBCL only)"
     :short-name #\c
     :long-name "compression"
     :initial-value 9
     :key :compression))
   :handler #'save-handler))

(defun root-command ()
  "Define the root command."
  (clingon:make-command
   :name "lda"
   :description "Lispy Data Analysis - Remote REPL tool for data analysis with DuckDB and Vega-Lite"
   :version "0.1.0"
   :authors '("Yacin Nadji <ynadji@gmail.com>")
   :license "MIT"
   :sub-commands
   (list
    (server-command)
    (repl-command)
    (save-command))
   :handler (lambda (cmd)
              (declare (ignore cmd))
              (clingon:print-usage-and-exit cmd t))))

;;; ---------------------------------------------------------------------------
;;; Main Entry Point
;;; ---------------------------------------------------------------------------

(defun main ()
  "Main entry point for the CLI application."
  (let ((app (root-command)))
    (clingon:run app)))
