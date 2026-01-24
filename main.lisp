(ql:quickload :duckdb)
(ql:quickload :alexandria)
(ql:quickload :com.inuoe.jzon)

(defpackage :lispy-data-analysis
  (:use :cl)
  (:nicknames :lda)
  (:local-nicknames (:db :duckdb)
                    (:ax :alexandria)
                    (:jzon :com.inuoe.jzon)))

(in-package :lispy-data-analysis)

(defun init-db ()
  (db:initialize-default-connection :allow-unsigned-extensions t)
  (db:run "LOAD '/Users/yacin/code/zeek-duckdb/build/release/extension/zeek/zeek.duckdb_extension'")
  (db:run "CREATE TABLE conn AS SELECT * FROM read_zeek('data/2026-01-16/conn_2*')"))

;;; ---------------------------------------------------------------------------
;;; Vega-Lite Visualization Utilities
;;; ---------------------------------------------------------------------------

(defun duckdb-results->vega-data (results)
  "Convert DuckDB query results (alist of column-name . vector) to Vega-Lite data format.
   Input:  ((\"app\" . #(\"foo\" \"bar\")) (\"freq\" . #(100 200)))
   Output: #((:app \"foo\" :freq 100) (:app \"bar\" :freq 200))"
  (let* ((columns (mapcar #'car results))
         (vectors (mapcar #'cdr results))
         (n-rows (length (first vectors))))
    (coerce
     (loop for i from 0 below n-rows
           collect (let ((ht (make-hash-table :test 'equal)))
                     (loop for col in columns
                           for vec in vectors
                           do (setf (gethash col ht) (aref vec i)))
                     ht))
     'vector)))

(defun plist->hash-table (plist)
  "Convert a plist to a hash table with string keys (lowercase).
   Example: (:size 100 :filled t) -> {\"size\": 100, \"filled\": true}"
  (let ((ht (make-hash-table :test 'equal)))
    (loop for (k v) on plist by #'cddr
          do (setf (gethash (string-downcase (symbol-name k)) ht) v))
    ht))

(defun make-mark (type &optional properties)
  "Create a mark specification.
   TYPE: mark type string (e.g., \"bar\", \"point\", \"line\")
   PROPERTIES: optional plist of mark properties

   If PROPERTIES is nil, returns just the type string.
   Otherwise returns a hash table with type and properties.

   Common properties by mark type:
     All marks: :color :opacity :fill :stroke :stroke-width :tooltip
     point:     :size :shape :filled
     line:      :stroke-width :interpolate :point
     area:      :line :opacity :interpolate
     bar:       :corner-radius :corner-radius-end
     text:      :font-size :font-weight :align :baseline :angle
     circle/square: :size
     rule:      :stroke-width
     tick:      :thickness
     arc:       :inner-radius :outer-radius :theta :theta2"
  (if (null properties)
      type
      (let ((ht (plist->hash-table properties)))
        (setf (gethash "type" ht) type)
        ht)))

(defun make-vega-spec (&key data mark encoding title width height)
  "Create a Vega-Lite specification as a hash table.
   DATA: vector of hash tables (from duckdb-results->vega-data)
   MARK: mark type string OR hash table from make-mark
   ENCODING: hash table with x, y, color, etc. encodings
   TITLE: optional chart title
   WIDTH/HEIGHT: optional dimensions"
  (let ((spec (make-hash-table :test 'equal)))
    (setf (gethash "$schema" spec) "https://vega.github.io/schema/vega-lite/v5.json")
    (when title (setf (gethash "title" spec) title))
    (when width (setf (gethash "width" spec) width))
    (when height (setf (gethash "height" spec) height))
    (let ((data-ht (make-hash-table :test 'equal)))
      (setf (gethash "values" data-ht) data)
      (setf (gethash "data" spec) data-ht))
    (setf (gethash "mark" spec) mark)
    (setf (gethash "encoding" spec) encoding)
    spec))

(defun make-encoding (&key x y color tooltip)
  "Create a Vega-Lite encoding hash table.
   Each parameter should be a plist like (:field \"name\" :type \"nominal\")
   Supported types: nominal, ordinal, quantitative, temporal"
  (let ((enc (make-hash-table :test 'equal)))
    (labels ((plist->ht (plist)
               (when plist
                 (let ((ht (make-hash-table :test 'equal)))
                   (loop for (k v) on plist by #'cddr
                         do (setf (gethash (string-downcase (symbol-name k)) ht) v))
                   ht))))
      (when x (setf (gethash "x" enc) (plist->ht x)))
      (when y (setf (gethash "y" enc) (plist->ht y)))
      (when color (setf (gethash "color" enc) (plist->ht color)))
      (when tooltip (setf (gethash "tooltip" enc) (plist->ht tooltip))))
    enc))

(defun make-bar-chart (results x-field y-field &key title (width 600) (height 400) x-sort mark-properties)
  "Convenience function to create a bar chart from DuckDB results.
   RESULTS: output from db:q
   X-FIELD: column name for x-axis (string)
   Y-FIELD: column name for y-axis (string)
   X-SORT: optional sort order, e.g., \"-y\" to sort by y descending
   MARK-PROPERTIES: optional plist of bar mark properties (e.g., :corner-radius 5)"
  (let* ((data (duckdb-results->vega-data results))
         (x-encoding (list :field x-field :type "nominal"))
         (y-encoding (list :field y-field :type "quantitative")))
    (when x-sort
      (setf x-encoding (append x-encoding (list :sort x-sort))))
    (make-vega-spec
     :data data
     :mark (make-mark "bar" mark-properties)
     :encoding (make-encoding :x x-encoding :y y-encoding)
     :title title
     :width width
     :height height)))

(defun vega-html-page (spec &key (title "Vega-Lite Chart"))
  "Generate a standalone HTML page with embedded Vega-Lite chart.
   SPEC: Vega-Lite specification (hash table from make-vega-spec or make-bar-chart)"
  (format nil "<!DOCTYPE html>
<html>
<head>
  <meta charset=\"utf-8\">
  <title>~A</title>
  <script src=\"https://cdn.jsdelivr.net/npm/vega@5\"></script>
  <script src=\"https://cdn.jsdelivr.net/npm/vega-lite@5\"></script>
  <script src=\"https://cdn.jsdelivr.net/npm/vega-embed@6\"></script>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 20px; }
    #vis { margin: 20px 0; }
  </style>
</head>
<body>
  <div id=\"vis\"></div>
  <script>
    const spec = ~A;
    vegaEmbed('#vis', spec, {actions: true}).catch(console.error);
  </script>
</body>
</html>"
          title
          (jzon:stringify spec :pretty t)))

(defun save-chart (spec path &key (title "Vega-Lite Chart") (open t))
  "Save a Vega-Lite chart to an HTML file and optionally open it in the browser.
   SPEC: Vega-Lite specification (from make-vega-spec or make-bar-chart)
   PATH: output file path (string or pathname)
   TITLE: HTML page title
   OPEN: if T, open the file in the default browser (macOS only for now)"
  (let ((html (vega-html-page spec :title title))
        (full-path (if (pathnamep path) path (pathname path))))
    (with-open-file (out full-path :direction :output :if-exists :supersede)
      (write-string html out))
    (when open
      ;; macOS-specific; could extend for Linux (xdg-open) / Windows (start)
      (uiop:run-program (list "open" (namestring full-path))))
    full-path))

(defun chart (results x-field y-field &key
                                        (path "/tmp/chart.html")
                                        title
                                        (width 600)
                                        (height 400)
                                        (mark "bar")
                                        mark-properties
                                        x-sort
                                        (open t))
  "One-liner to create and display a chart from DuckDB query results.
   RESULTS: output from db:q
   X-FIELD: column name for x-axis
   Y-FIELD: column name for y-axis
   MARK: mark type string (default \"bar\")
   MARK-PROPERTIES: optional plist of mark properties

   Examples:
     ;; Simple bar chart
     (chart (db:q \"SELECT app, COUNT(*) as freq FROM apps GROUP BY app\")
            \"app\" \"freq\"
            :title \"App Frequency\"
            :x-sort \"-y\")

     ;; Scatter plot with custom point size and shape
     (chart results \"x\" \"y\"
            :mark \"point\"
            :mark-properties '(:size 100 :filled t :opacity 0.7))

     ;; Line chart with smooth interpolation
     (chart results \"date\" \"value\"
            :mark \"line\"
            :mark-properties '(:stroke-width 3 :interpolate \"monotone\"))

     ;; Area chart with transparency
     (chart results \"date\" \"value\"
            :mark \"area\"
            :mark-properties '(:opacity 0.5 :line t))"
  (let* ((data (duckdb-results->vega-data results))
         (x-enc (if x-sort
                    (list :field x-field :type "nominal" :sort x-sort)
                    (list :field x-field :type "nominal")))
         (y-enc (list :field y-field :type "quantitative"))
         (mark-spec (make-mark mark mark-properties))
         (spec (make-vega-spec
                :data data
                :mark mark-spec
                :encoding (make-encoding :x x-enc :y y-enc)
                :title title
                :width width
                :height height)))
    (save-chart spec path :title (or title "Chart") :open open)))

(defparameter *example-spec*
  (let* ((results (db:q "SELECT app, COUNT(*) AS freq
              FROM (SELECT UNNEST(app) AS app FROM conn)
              GROUP BY app ORDER BY freq DESC LIMIT 20"))
         (data (duckdb-results->vega-data results))
         (spec (make-vega-spec :data data :mark "bar"
                               :encoding (make-encoding :x (list :field "app" :type "nominal" :sort "-y")
                                                        :y (list :field "freq" :type "quantitative"))
                               :title "app breakdown" :width 600 :height 400)))
    (jzon:stringify spec)))
