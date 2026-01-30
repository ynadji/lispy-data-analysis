(in-package :lispy-data-analysis)

(defvar *db* nil
  "Global DuckDB connection.")

(defun init-db (&key (extension-path "~/code/zeek-duckdb/build/release/extension/zeek/zeek.duckdb_extension")
                     (allow-unsigned-extensions t))
  "Initialize DuckDB connection and load the zeek-duckdb extension.
   EXTENSION-PATH: Path to the zeek.duckdb_extension file
   ALLOW-UNSIGNED-EXTENSIONS: Whether to allow loading unsigned extensions

   Exits with error code 1 if the extension file is not found."
  (let ((expanded-path (uiop:native-namestring (uiop:parse-unix-namestring extension-path))))
    ;; Check if extension file exists
    (unless (probe-file expanded-path)
      (format *error-output* "ERROR: Zeek DuckDB extension not found at: ~A~%" expanded-path)
      (format *error-output* "Please build the zeek-duckdb extension or specify a different path.~%")
      (uiop:quit 1))

    ;; Initialize DuckDB connection
    (setf *db* (db:initialize-default-connection :allow-unsigned-extensions allow-unsigned-extensions))

    ;; Load the zeek extension
    (handler-case
        (db:run (format nil "LOAD '~A'" expanded-path))
      (error (e)
        (format *error-output* "ERROR: Failed to load zeek extension: ~A~%" e)
        (uiop:quit 1)))

    (format t "DuckDB initialized with zeek extension loaded from ~A~%" expanded-path)
    *db*))

#+sbcl
(defun save-state-and-die (&key (compression 9))
  "Save the current Lisp image, overwriting the executable in-place.
   COMPRESSION: Compression level 0-9 (default 9, SBCL only)

   This will terminate the current process and overwrite the binary with the current state."
  (let ((executable-path (first (uiop:raw-command-line-arguments))))
    (format t "Saving Lisp image to: ~A~%" executable-path)
    (format t "WARNING: This will terminate the process.~%")
    (sb-ext:save-lisp-and-die executable-path
                               :executable t
                               :compression compression)))

#-sbcl
(defun save-state-and-die (&key compression)
  "Save state is only supported on SBCL."
  (declare (ignore compression))
  (error "SAVE-STATE-AND-DIE is only supported on SBCL."))
