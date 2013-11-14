(define call/cc call-with-current-continuation)
(define (list . x) x)
(define (not x) (if x #f #t))
(define (negative? x) (< x 0))
(define (positive? x) (> x 0))
(define (even? x) (= (remainder x 2) 0))
(define (odd? x) (not (even? x)))
(define (zero? x) (= x 0))
(define (abs x) (if (< x 0) (- x) x))
(define magnitude abs)
(define exact? integer?)
(define (inexact? x) (not (exact? x)))
(define (random x) (floor (* (rnd) x)))
(define (1+ x) (+ x 1))
(define (1- x) (- x 1))
(define add1 1+)
(define sub1 1-)
;
(define (char-ci=?  x y) (char=?  (char-downcase x) (char-downcase y)))
(define (char-ci>?  x y) (char>?  (char-downcase x) (char-downcase y)))
(define (char-ci<?  x y) (char<?  (char-downcase x) (char-downcase y)))
(define (char-ci>=? x y) (char>=? (char-downcase x) (char-downcase y)))
(define (char-ci<=? x y) (char<=? (char-downcase x) (char-downcase y)))
(define (char-lower-case? x) (char=? x (char-downcase x)))
(define (char-upper-case? x) (char=? x (char-upcase x)))
(define (char-alphabetic? x) (if (char-ci>=? x #\a) (char-ci<=? x #\z) #f))
(define (char-numeric? x) (if (char>=? x #\0) (char<=? x #\9) #f))
(define (char-whitespace? x) (char<=? x #\space))
(define (string-ci=?  x y) (string=?  (string-downcase x) (string-downcase y)))
(define (string-ci>?  x y) (string>?  (string-downcase x) (string-downcase y)))
(define (string-ci<?  x y) (string<?  (string-downcase x) (string-downcase y)))
(define (string-ci>=? x y) (string>=? (string-downcase x) (string-downcase y)))
(define (string-ci<=? x y) (string<=? (string-downcase x) (string-downcase y)))
;
(define (map f ls . more)
  (define (map1 l)
    (if (null? l)
      '()
      (if (pair? l)
          (cons (f (car l)) (map1 (cdr l)))
          (f l))))
  (define (map-more l m)
    (if (null? l)
        '()
        (if (pair? l)
            (cons (apply f (car l) (map car m))
                  (map-more (cdr l)
                            (map cdr m)))
            (apply f l m))))
  (if (null? more)
      (map1 ls)
      (map-more ls more)))
; tail-recursive map
(define (map+ f . lst)
  (define r '())
  (define o #f)
  (define p #f)
  (define (map-lst op l)
    (if (pair? l) (cons (op (car l)) (map-lst op (cdr l))) '()))
  (define (do-map)
    (if (pair? (car lst)) (begin
          (set! o (cons (apply f (map car lst)) '()))
          (if (null? r) (set! r o) (set-cdr! p o))
          (set! p o)
          (set! lst (map cdr lst))
          (do-map))
      (if (not (null? (car lst)))
         (if p (set-cdr! p (apply f lst))
               (set! r (apply f lst))))))
  (do-map) r)
;
(define (caar x) (car (car x)))
(define (cadr x) (car (cdr x)))
(define (cdar x) (cdr (car x)))
(define (cddr x) (cdr (cdr x)))
;
(define (caaar x) (car (car (car x))))
(define (caadr x) (car (car (cdr x))))
(define (cadar x) (car (cdr (car x))))
(define (caddr x) (car (cdr (cdr x))))
(define (cdaar x) (cdr (car (car x))))
(define (cdadr x) (cdr (car (cdr x))))
(define (cddar x) (cdr (cdr (car x))))
(define (cdddr x) (cdr (cdr (cdr x))))
;
(define (caaddr x) (car (car (cdr (cdr x)))))
(define (cadddr x) (car (cdr (cdr (cdr x)))))
(define (cdaddr x) (cdr (car (cdr (cdr x)))))
(define (cddddr x) (cdr (cdr (cdr (cdr x)))))
;
(define (length lst . x)
  (define l (if (null? x) 0 (car x)))
  (if (pair? lst) (length (cdr lst) (+ l 1)) l))
(define (length+ lst . x)
  (define l (if (null? x) 0 (car x)))
  (if (null? lst) l
      (if (pair? lst) (length+ (cdr lst) (+ l 1)) (+ l 1))))

(define (list-ref lst n)
  (if (= n 0) (car lst) (list-ref (cdr lst) (- n 1))))
(define (list-tail lst n)
  (if (= n 0) lst (list-tail (cdr lst) (- n 1))))
(define (reverse lst . l2)
  (define r (if (null? l2) l2 (car l2)))
  (if (null? lst) r
      (reverse (cdr lst) (cons (car lst) r))))
;
(define (append l1 . more)
  (define (append2 l2 m2)
    (if (null? l1)
        (apply append l2 m2)
      (cons (car l1)
            (apply append (cdr l1) l2 m2))))
  (if (null? more) l1
    (append2 (car more) (cdr more))))
;
(define sort #f)
(define merge #f)
((lambda ()
  (define dosort
    (lambda (pred? ls n)
      (if (= n 1) (list (car ls))
          (if (= n 2)
              (let ([x (car ls)]
                    [y (cadr ls)])
                     (if (pred? y x) (list y x) (list x y)))
              (let ([i (quotient n 2)])
                     (domerge pred?
                              (dosort pred? ls i)
                              (dosort pred? (list-tail ls i) (- n i))))))))
  (define domerge
    (lambda (pred? l1 l2)
      (if (null? l1)
          l2
          (if (null? l2)
              l1
              (if (pred? (car l2) (car l1))
                  (cons (car l2) (domerge pred? l1 (cdr l2)))
                  (cons (car l1) (domerge pred? (cdr l1) l2)))))))
  (set! sort
    (lambda (pred? l)
      (if (null? l) l (dosort pred? l (length l)))))
  (set! merge
    (lambda (pred? l1 l2)
      (domerge pred? l1 l2)))))
;
(define (iota count . x)
  (define start 0)
  (define step 1)
  (if (not (null? x)) (begin (set! start (car x))
  (if (not (null? (cdr x))) (begin (set! step (cadr x))))))
  (define (do-step cnt lst)
    (if (< cnt 0) lst
        (do-step (- cnt 1) (cons (+ (* step cnt) start) lst))))
  (do-step (- count 1) '()))
;
(define (list->string lst) (apply string lst))
;
(define (gcd a b) ; 2Do: (gcd) => 0
  (if (= b 0)
      a
      (gcd b (remainder a b))))
(define (lcm x y) (/ (* x y) (gcd x y))) ; 2Do: (lcm) => 1
;
(define (max x . l)
  (if (null? l) x
      (apply max (if (> x (car l)) x (car l)) (cdr l))))
(define (min x . l)
  (if (null? l) x
      (apply max (if (< x (car l)) x (car l)) (cdr l))))
;
(define syntax-quasiquote ((lambda ()
  (define (ql x)
    (if (pair? x)
        (if (null? x)
            ''()
            (if (eq? (car x) 'unquote)
                (cadr x)
                (if (if (pair? (car x))
                        (eq? (caar x) 'unquote-splicing)
                        #f)
                    (if (null? (cdr x))
                        (cadar x)
                        (list 'append (cadar x) (ql (cdr x))))
                    (if (null? (cdr x))
                        (list 'list (ql (car x)))
                        (list 'cons (ql (car x)) (ql (cdr x)))))))
        (if (symbol? x) (list 'quote x) x)))
  (lambda (expr)
  (ql (cadr expr))))))
(define-syntax quasiquote (syntax-quasiquote))
;
(define (f-and . lst)
  (if (null? lst) #t
      (if (car lst) (apply f-and (cdr lst)) #f)))
(define (f-or . lst)
  (if (null? lst) #f
      (if (car lst) #t (apply f-or (cdr lst)))))
;
(define (syntax-rules expr literals p1 . more)
  (define vars '())
  ;
  (define (match ex pat)
    (if (null? pat) (null? ex)
      (if (symbol? pat)
        (begin (set! vars (cons (cons pat ex) vars)) #t)
        (if (eq? (cadr pat) '...)
            (match-many ex (car pat))
            (if (if (null? ex) #f
                (if (memq+ (car pat) literals)
                    (eq? (car pat) (car ex))
                    (if (symbol? (car pat))
                        (begin
                           (set! vars (cons (cons (car pat) (car ex)) vars))
                           #t)
                        (if (if (pair? (car pat))
                                (if (null? (car ex)) #t (pair? (car ex)))
                                #f)
                            (match (car ex) (car pat))
                            (eqv? (car pat) (car ex)))))) ; equal?
                (match (cdr ex) (cdr pat))
                #f)))))
  ;
  (define (match-many ex pat)
    (if (null? ex) #t
        (if (match (list (car ex)) (list pat))
            (match-many (cdr ex) pat)
            #f)))
  ;
  (define (find-all var lst out)
    (if (null? lst)
        out
        (if (eq? var (caar lst))
            (find-all var (cdr lst) (cons (cdar lst) out))
            (find-all var (cdr lst) out))))
  ;
  (define (p-each lst templ)
    (if (null? lst)
        '()
        (cons (if (null? (car lst)) (car templ) (caar lst))
              (p-each (cdr lst) (cdr templ)))))
  ;
  (define (process-many lst templ)
    (define not-empty #f)
    (define (l2 l)
      (if (null? l)
          '()
        ((lambda (a)
           (if (not (null? a))
               (begin (set! not-empty #t) (set! a (cdr a))))
           (cons a (l2 (cdr l))))
         (car l))))
    (define ll (l2 lst))
    (if not-empty
        (cons (p-each lst templ)
              (process-many ll templ))
        '()))
  ;
  (define (gen-many templ)
    (if (null? templ)
        '()
        (if (pair? templ)
            (process-many (map+ gen-many templ) templ)
            (find-all templ vars '()))))
  ;
  (define (ren x)
    (define new #f)
    (if (eq? x '...)
        x
        (begin
          (set! new (gen-sym x))
          (set! vars (cons (cons x new) vars))
          new)))
  ; 2Do: generate temporary symbols in (define ...)
  (define (gen templ no...)
    (define old-vars #f)
    (define args #f)
    (define body #f)
    (define new #f)
    (define x #f)
    ;
    (if (null? templ)
        '()
        (if (pair? templ)
            (if (if no... (eq? (cadr templ) '...) #f)
                (append (gen-many (car templ))
                        (gen (cddr templ) no...))
                (if (if no... (eq? (car templ) 'lambda) #f)
                    (begin
                      (set! old-vars vars)
                      (set! args (gen (cadr templ) no...))
                      (set! body (gen (cddr templ) no...))
                      (set! vars '())
                      (set! new (map+ ren args))
                      (set! new
                        (cons (car templ)
                              (cons new
                                    (gen body #f))))
                      (set! vars old-vars)
                      new)
                    (cons (gen (car templ) no...) (gen (cdr templ) no...))))
            (begin
              (set! x (assq templ vars))
              (if x (cdr x) templ)))))
  ;
  (if (match (cdr expr) (cdar p1))
      (gen (cadr p1) #t)
      (if (null? more)
          (error (string-append "no pattern matches "
                                (symbol->string (car expr))))
          (apply syntax-rules expr literals more))))
;
(define-syntax and
  (syntax-rules ()
  ((_) #t)
  ((_ test) test)
  ((_ test1 test2 ...)
    (if test1 (and test2 ...) #f))))
;
(define-syntax or
  (syntax-rules ()
    ((_) #f)
    ((_ test) test)
    ((_ test1 test2 ...)
     (let ((_tmp_ test1))
       (if _tmp_ _tmp_ (or test2 ...))))))
;
(define-syntax let
  (syntax-rules ()
    ((_ ((name val) ...) body1 ...)
     ((lambda (name ...) body1 ...)
      val ...))
    ((_ tag ((name val) ...) body1 ...)
    ((letrec ((tag (lambda (name ...)
                     body1 ...))) tag)
      val ...))))
;
(define-syntax cond
  (syntax-rules (else =>)
    ((_ (else result1 ...))
     (begin result1 ...))
    ((_ (test => result))
     (let ((_tmp_ test))
       (if _tmp_ (result _tmp_))))
    ((_ (test => result) clause1 ...)
     (let ((_tmp_ test))
       (if _tmp_
           (result _tmp_)
           (cond clause1 ...))))
    ((_ (test)) test)
    ((_ (test) clause1 ...)
     (let ((_tmp_ test))
       (if _tmp_ _tmp_
           (cond clause1 ...))))
    ((_ (test result1 ...))
     (if test (begin result1 ...)))
    ((_ (test result1 ...)
           clause1 ...)
     (if test
         (begin result1 ...)
         (cond clause1 ...)))))
;
(define-syntax let*
  (syntax-rules ()
    ((_ () body1 ...)
     (begin body1 ...))
    ((_ ((name1 val1) (name2 val2) ...) body1 ...)
     ((lambda (name1) (let* ((name2 val2) ...) body1 ...)) val1))))
(define-syntax letrec
  (syntax-rules ()
    ((_ ((var1 init1) ...) body ...)
     ((lambda ()
       (define var1 #f) ...
       ((lambda _tmplst_
          (begin (set! var1 (car _tmplst_))
                 (set! _tmplst_ (cdr _tmplst_))) ...) init1 ...)
       body ...)))))
(define-syntax let-syntax
  (syntax-rules ()
    ((_ ((_var1_ _init1_) ...) _body_ ...)
     ((lambda () (define-syntax _var1_ _init1_) ... _body_ ...)))))
(define letrec-syntax let-syntax)
;
(define-syntax case
  (syntax-rules (else)
    ((_ (key ...)
       clauses ...)
     (let ((_tmp_ (key ...)))
       (case _tmp_ clauses ...)))
    ((_ key
       (else result1 ...))
     (begin result1 ...))
    ((_ key
       ((atoms ...) result1 ...))
     (if (memv key '(atoms ...))
         (begin result1 ...)))
    ((_ key
       ((atoms ...) result1 ...)
       clause ...)
     (if (memv key '(atoms ...))
         (begin result1 ...)
         (case key clause ...)))))
;
(define-syntax do
  (syntax-rules ()
    ((_ ((var init step) ...)
        (test expr ...)
        command ...)
     (letrec ; 2Do: simplify!
       ((_loop_
         (lambda (var ...)
           (if test
               (begin expr ...)
               (begin
                 command ...
                 (_loop_ (do "step" var step) ...))))))
       (_loop_ init ...)))
    ((_ "step" x) x)
    ((_ "step" x y) y)))
;
(define (memq+ x ls)
  (if (pair? ls)
      (if (eq? (car ls) x) ls
          (memq+ x (cdr ls)))
      (if (eq? x ls) ls #f)))
(define memq memq+)
(define (memv x ls)
  (if (pair? ls)
      (if (eqv? (car ls) x) ls
          (memv x (cdr ls)))
  (if (eqv? x ls) ls #f)))
(define (member x ls)
  (if (pair? ls)
      (if (equal? (car ls) x) ls
          (member x (cdr ls)))
  (if (equal? x ls) ls #f)))
;
(define (assq x ls)
  (if (null? ls) #f
      (if (eq? (caar ls) x) (car ls)
          (assq x (cdr ls)))))
(define (assv x ls)
  (if (null? ls) #f
      (if (eqv? (caar ls) x) (car ls)
          (assv x (cdr ls)))))
(define (assoc x ls)
  (if (null? ls) #f
      (if (equal? (caar ls) x) (car ls)
          (assoc x (cdr ls)))))
;
(define list?
  ((lambda ()
    (define (race h t)
      (if (pair? h)
          ((lambda (h)
             (if (pair? h)
                 (if (not (eq? h t))
                     (race (cdr h) (cdr t))
                     #f)
                 (null? h))) (cdr h))
          (null? h)))
    (lambda (x) (race x x)))))
;
(define equal?
  (lambda (x y)
    ((lambda (eqv)
       (if eqv eqv
           (if (pair? x)
               (begin
                 (if (pair? y)
                     (if (equal? (car x) (car y))
                         (equal? (cdr x) (cdr y))
                         #f)
                     #f))
                 (if (vector? x)
                     (if (vector? y)
                         ((lambda (n)
                            (if (= (vector-length y) n)
                                ((let 
                                   ([loop
                                     (lambda (i)
                                       ((lambda (eq-len)
                                          (if eq-len
                                              eq-len
                                              (if (equal? (vector-ref x i)
                                                          (vector-ref y i))
                                                  (loop (+ i 1))
                                                  #f)))
                                        (= i n)))])
                                   loop)
                                 0)
                                #f))
                          (vector-length x))
                         #f)
                     #f))))
     (eqv? x y))))
(define (values . things)
  (call/cc
    (lambda (cont) (apply cont things))))
(define (call-with-values producer consumer)
  (consumer (producer)))
;
(define (for-each f . lst)
  (if (not (null? (car lst))) (begin
      (apply f (map+ car lst))
      (apply for-each f (map+ cdr lst)))))
;
(define-syntax delay
  (syntax-rules ()
    ((_ exp) (make-promise (lambda () exp)))))
(define (make-promise p)
  ((lambda ()
    (define val #f)
    (define set? #f)
    (lambda ()
      (if (not set?)
          (let ([x (p)])
            (if (not set?)
                (begin (set! val x)
                       (set! set? #t)))))
      val))))
(define (force promise) (promise))
;
(define (string-copy x) x)
(define (vector-fill! v obj)
  (define l (vector-length v))
  (define (vf i) (if (< i l) (begin (vector-set! v i obj) (vf (+ i 1)))))
  (vf 0))
(define (vector->list v)
  (define (loop i l)
    (if (< i 0)
        l
        (loop (- i 1) (cons (vector-ref v i) l))))
  (loop (- (vector-length v) 1) '()))
(define (list->vector l)
  (define v (make-vector 0)) ; js :)
  (define (loop i l)
    (if (pair? l)
        (begin (vector-set! v i (car l))
               (loop (+ i 1) (cdr l)))
        (if (not (null? l)) (vector-set! v i l))))
  (loop 0 l) v)
;
(define dynamic-wind #f)
((lambda ()

  (define winders '())

  (define (common-tail x y)
     (define lx (length x))
     (define ly (length y))
     (define (loop x y)
       (if (eq? x y)
           x
           (loop (cdr x) (cdr y))))
     (loop (if (> lx ly) (list-tail x (- lx ly)) x)
           (if (> ly lx) (list-tail y (- ly lx)) y)))

  (define (do-wind new)
    (define tail (common-tail new winders))
    (define (f1 l)
      (if (not (eq? l tail))
          (begin
            (set! winders (cdr l))
            ((cdar l))
            (f1 (cdr l)))))
    (define (f2 l)
      (if (not (eq? l tail))
          (begin
            (f2 (cdr l))
            ((caar l))
            (set! winders l))))
    (f1 winders)
    (f2 new))

  ((lambda (c)
    (set! call/cc
      (lambda (f)
        (c (lambda (k)
             (f ((lambda (save)
                  (lambda x
                    (if (not (eq? save winders)) (do-wind save))
                    (apply k x)))
                 winders)))))))
      call/cc)
  (set! call-with-current-continuation call/cc)

  (set! dynamic-wind
    (lambda (in body out)
      (define ans #f)
      (in)
      (set! winders (cons (cons in out) winders))
      (set! ans (body))
      (set! winders (cdr winders))
      (out)
      ans))))
;
(define (js-char c)
  (define char-code (char->integer c))
  (if (>= char-code 32) (string c)
      (string-append "\\x" (if (< char-code 16) "0" "")
                     (number->string char-code 16))))

(define (transform ex)
  (if (pair? ex)
      (if (symbol? (car ex))
          (if (eq? (car ex) 'quote)
              ex
            (if (if (eq? (car ex) 'begin)
                    (if (null? (cdr ex)) #f (null? (cddr ex))) #f)
                (transform (cadr ex))
              (if (if (eq? (car ex) 'lambda) #t
                    (if (eq? (car ex) 'define) #t
                      (eq? (car ex) 'set!)))
                  (cons (car ex) (cons (cadr ex) (map+ transform (cddr ex))))
                ((lambda (x)
                   (if (syntax? x)
                       (transform (apply (get-prop x "transformer") ex (get-prop x "args")))
                     (cons (car ex) (map+ transform (cdr ex)))))
                 (eval (car ex)))   )))
        (map+ transform ex))
    ex))
