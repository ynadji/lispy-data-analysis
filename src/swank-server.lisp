(in-package :lispy-data-analysis)

(defvar *swank-server-thread* nil
  "Background thread running the swank server.")

(defvar *swank-server-port* nil
  "Port the swank server is running on.")

(defun start-swank-server (&key (port 4005) (host "127.0.0.1") password (daemon nil))
  "Start swank server in a background thread for remote REPL access.
   PORT: Port to listen on (default: 4005)
   HOST: Host to bind to (default: 127.0.0.1 for localhost-only)
   PASSWORD: Optional password for authentication
   DAEMON: If T, block the main thread (for server mode). If NIL, return immediately (for REPL mode).

   Authentication modes:
     - With PASSWORD: Requires password authentication for connections
     - Without PASSWORD + HOST=127.0.0.1: Localhost-only binding (secure by default)
     - Without PASSWORD + HOST=0.0.0.0: Listen on all interfaces (use with caution)

   Examples:
     ;; Localhost-only, no password (secure for SSH tunneling)
     (start-swank-server :port 4005)

     ;; Password authentication
     (start-swank-server :port 4005 :password \"secret123\")

     ;; Listen on all interfaces with password (for remote access)
     (start-swank-server :port 4005 :host \"0.0.0.0\" :password \"secret123\")"

  ;; Load swank if not already loaded
  (unless (find-package :swank)
    (require :swank))

  ;; Stop existing server if running
  (when *swank-server-thread*
    (stop-swank-server))

  ;; Configure swank
  (let ((swank-package (find-package :swank)))
    (when password
      (setf (symbol-value (find-symbol "*USE-DEDICATED-OUTPUT-STREAM*" swank-package)) nil)
      (setf (symbol-value (find-symbol "*COMMUNICATION-STYLE*" swank-package)) :fd-handler)))

  ;; Start swank in a background thread
  (setf *swank-server-port* port)
  (setf *swank-server-thread*
        (bt:make-thread
         (lambda ()
           (handler-case
               (let ((swank-package (find-package :swank)))
                 (if password
                     ;; Start with password authentication
                     (funcall (find-symbol "CREATE-SERVER" swank-package)
                              :port port
                              :interface host
                              :dont-close t
                              :coding-system "utf-8-unix"
                              :style :fd-handler
                              :password password)
                     ;; Start without password
                     (funcall (find-symbol "CREATE-SERVER" swank-package)
                              :port port
                              :interface host
                              :dont-close t
                              :coding-system "utf-8-unix")))
             (error (e)
               (format *error-output* "ERROR: Swank server failed: ~A~%" e))))
         :name "swank-server"))

  ;; Print connection info
  (format t "Swank server started on ~A:~A~%" host port)
  (when password
    (format t "Password authentication enabled~%"))
  (unless (or password (equal host "127.0.0.1") (equal host "localhost"))
    (format t "WARNING: Server listening on all interfaces without password authentication~%"))

  ;; If daemon mode, block the main thread
  (when daemon
    (format t "Running in daemon mode. Press Ctrl-C to stop.~%")
    (handler-case
        (loop (sleep 60))
      (#+sbcl sb-sys:interactive-interrupt
       #+ccl ccl:interrupt-signal-condition
       #+clisp system::simple-interrupt-condition
       #+ecl ext:interactive-interrupt
       #+allegro excl:interrupt-signal
       ()
       (format t "~%Interrupt received, shutting down...~%")
       (stop-swank-server)
       (uiop:quit 0))))

  ;; Return the thread
  *swank-server-thread*)

(defun stop-swank-server ()
  "Stop the swank server gracefully."
  (when *swank-server-thread*
    (let ((swank-package (find-package :swank)))
      (when swank-package
        (handler-case
            (funcall (find-symbol "STOP-SERVER" swank-package) *swank-server-port*)
          (error (e)
            (format *error-output* "Warning: Error stopping swank server: ~A~%" e)))))

    ;; Wait for thread to finish (with timeout)
    (when (bt:thread-alive-p *swank-server-thread*)
      (handler-case
          (bt:join-thread *swank-server-thread*)
        (error (e)
          (format *error-output* "Warning: Error joining swank thread: ~A~%" e))))

    (setf *swank-server-thread* nil)
    (setf *swank-server-port* nil)
    (format t "Swank server stopped.~%")))
