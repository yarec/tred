;
; Simple continuation test
;
(define retry #f)

(define factorial
  (lambda (x)
    (if (= x 0)
        (call/cc (lambda (k) (set! retry k) 1))
      (* x (factorial (- x 1))))))
(display
 (factorial 4))

(display
 (retry 1))
(display
 (retry 2))

(display
 (retry 5))
