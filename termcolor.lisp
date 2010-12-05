(cl:in-package #:cl-user)

(cl:defpackage #:termcolor
  (:use #:cl)
  (:export #:color #:fg #:bg #:style #:reset))

(in-package #:termcolor)

(defvar *hashes*
  (list :fg (make-hash-table)
        :bg (make-hash-table)
        :style (make-hash-table)))

(defun defcolor (type name value)
  (let ((hash (or (getf *hashes* type) (error "Invalid color type: ~A" type))))
    (setf (gethash name hash) value)))

(defcolor :STYLE :RESET  0)
(defcolor :STYLE :BRIGHT 1)
(defcolor :STYLE :DIM    2)
(defcolor :STYLE :NORMAL 22)

(defcolor :FG    :BLACK  30)
(defcolor :FG    :RED    31)
(defcolor :FG    :GREEN  32)
(defcolor :FG    :YELLOW 33)
(defcolor :FG    :BLUE   34)
(defcolor :FG    :VIOLET 35)
(defcolor :FG    :CYAN   36)
(defcolor :FG    :WHITE  37)
(defcolor :FG    :RESET  39)

(defcolor :BG    :BLACK  40)
(defcolor :BG    :RED    41)
(defcolor :BG    :GREEN  42)
(defcolor :BG    :YELLOW 43)
(defcolor :BG    :BLUE   44)
(defcolor :BG    :VIOLET 45)
(defcolor :BG    :CYAN   46)
(defcolor :BG    :WHITE  47)
(defcolor :BG    :RESET  49)

(defconstant +escape+ #\Esc)

(defun get-color (type name)
  (or (gethash name (getf *hashes* type))
      (when name (error "Invalid color ~A: ~A" type name))))

(defun %color (&key fg bg style)
  (assert (or fg bg style) (fg bg style)
          "None of FG, BG or STYLE given.")
  (format nil "~A[~@[~A~]~@[;~A~]~@[;~A~]m"
          +escape+
          (get-color :style style)
          (get-color :fg fg)
          (get-color :bg bg)))

(defun color (&key fg bg style stream)
  (write-string (%color :fg fg :bg bg :style style) stream))

(define-compiler-macro color (&whole form &key fg bg style stream)
  (if (and (or (null fg) (keywordp fg))
           (or (null bg) (keywordp bg))
           (or (null style) (keywordp style)))
      `(write-string ,(%color :fg fg :bg bg :style style) ,stream)
      form))

(defmacro def-colorfn (type)
  (let ((type-keyword (intern (string type) :keyword)))
    `(progn
       (defun ,type (name &key stream)
         (write-string (%color ,type-keyword name) stream))
       (define-compiler-macro ,type (&whole form name &key stream)
         (if (keywordp name)
             `(write-string ,(%color ,type-keyword name) ,stream)
             form)))))

(def-colorfn fg)
(def-colorfn bg)
(def-colorfn style)

(defun reset (&optional stream)
  (write-string (%color :style :reset) stream))

(define-compiler-macro reset (&optional stream)
  `(write-string ,(%color :style :reset) ,stream))
