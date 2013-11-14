(define (compile ex . tt)
  (define tail #f)
  (define locs #f)
  (define app "Apply")
  (define prefix "")
  (define suffix "")

  (if (not (null? tt))
    (begin (set! locs (car tt))
      (if (not (null? (cdr tt)))
        (begin (set! tail (cadr tt))
          (if (not (null? (cddr tt)))
            (begin (set! prefix (caddr tt))
                   (set! suffix (cadddr tt))))))))
  (if tail (set! app "TC"))

  (if (number? ex) (string-append prefix (number->string ex) suffix)
  (if (symbol? ex)
      (if locs
          (string-append prefix (locs 'gen ex "e") suffix)
         ; (string-append prefix "e['" (symbol->string ex) "']" suffix)
          (string-append prefix "e.get('" (symbol->string ex) "')" suffix))
  (if (string? ex) (string-append prefix (str ex) suffix)
  (if (char? ex) (string-append prefix "getChar('" (js-char ex) "')" suffix)
  (if (null? ex) (error "cannot compile ()")
  (if (boolean? ex) (string-append prefix (if ex "true" "false") suffix)
  (if (vector? ex)
      (string-append prefix app "(e.get('list->vector'),"
                     (if tail "list=" "") "new Pair("
                     (compile-quote (vector->list ex)) ",theNil),e)" suffix)
  (if (not (pair? ex)) (error (string-append "cannot compile " (str ex)))
  ;
  (compile-pair ex locs tail prefix suffix app))))))))))

(define (compile-pair ex locs tail prefix suffix app)
  (define list-len (if (pair? locs) (length locs) #f))

  (if (eq? (car ex) 'begin)  (compile-begin (cdr ex) locs tail prefix suffix)
  (if (eq? (car ex) 'quote)  (compile-quote (cadr ex) prefix suffix)
  (if (eq? (car ex) 'not)
      (compile (cadr ex) locs #f (string-append prefix "(") (string-append "==false)" suffix))
  (if (eq? (car ex) 'symbol->string)
      (compile (cadr ex) locs #f prefix (string-append suffix ".name"))
  (if (eq? (car ex) 'car)    (string-append prefix (compile (cadr ex) locs) ".car" suffix)
  (if (eq? (car ex) 'cdr)    (string-append prefix (compile (cadr ex) locs) ".cdr" suffix)
  (if (eq? (car ex) 'caar)   (string-append prefix (compile (cadr ex) locs) ".car.car" suffix)
  (if (eq? (car ex) 'cadr)   (string-append prefix (compile (cadr ex) locs) ".cdr.car" suffix)
  (if (eq? (car ex) 'cdar)   (string-append prefix (compile (cadr ex) locs) ".car.cdr" suffix)
  (if (eq? (car ex) 'cddr)   (string-append prefix (compile (cadr ex) locs) ".cdr.cdr" suffix)
  (if (eq? (car ex) 'caaar)  (string-append prefix (compile (cadr ex) locs) ".car.car.car" suffix)
  (if (eq? (car ex) 'caddr)  (string-append prefix (compile (cadr ex) locs) ".cdr.cdr.car" suffix)
  (if (eq? (car ex) 'cdaar)  (string-append prefix (compile (cadr ex) locs) ".car.car.cdr" suffix)
  (if (eq? (car ex) 'cdddr)  (string-append prefix (compile (cadr ex) locs) ".cdr.cdr.cdr" suffix)
  (if (eq? (car ex) 'caaddr) (string-append prefix (compile (cadr ex) locs) ".cdr.cdr.car.car" suffix)
  (if (eq? (car ex) 'cadddr) (string-append prefix (compile (cadr ex) locs) ".cdr.cdr.cdr.car" suffix)
  (if (eq? (car ex) 'cdaddr) (string-append prefix (compile (cadr ex) locs) ".cdr.cdr.car.cdr" suffix)
  (if (eq? (car ex) 'cddddr) (string-append prefix (compile (cadr ex) locs) ".cdr.cdr.cdr.cdr" suffix)
  (if (eq? (car ex) 'cons)
      (string-append prefix "new Pair(" (compile (cadr ex) locs)
                     "," (compile (caddr ex) locs) ")" suffix)
  (if (eq? (car ex) 'boolean?) (string-append prefix "(typeof(" (compile (cadr ex) locs) ")=='boolean')" suffix)
  (if (eq? (car ex) 'string?)  (string-append prefix "(typeof(" (compile (cadr ex) locs) ")=='string')" suffix)
  (if (eq? (car ex) 'number?)  (string-append prefix "(typeof(" (compile (cadr ex) locs) ")=='number')" suffix)
  (if (eq? (car ex) 'char?)    (string-append prefix "((" (compile (cadr ex) locs) ")instanceof Char)" suffix)
  (if (eq? (car ex) 'symbol?)  (string-append prefix "((" (compile (cadr ex) locs) ")instanceof Symbol)" suffix)
  (if (eq? (car ex) 'syntax?)  (string-append prefix "((" (compile (cadr ex) locs) ")instanceof Syntax)" suffix)
  (if (eq? (car ex) 'null?)    (string-append prefix "(" (compile (cadr ex) locs) "==theNil)" suffix)
  (if (eq? (car ex) 'pair?)    (string-append prefix "((" (compile (cadr ex) locs) ")instanceof Pair)" suffix)
  (if (eq? (car ex) 'str)      (string-append prefix "Str(" (compile (cadr ex) locs) ")" suffix)
  (if (eq? (car ex) 'clone)    (string-append prefix (compile (cadr ex) locs) ".clone(e)" suffix)
  (if (eq? (car ex) 'get-prop) (string-append prefix (compile (cadr ex) locs) "[" (str (caddr ex)) "]" suffix)
  (if (if (eq? (car ex) '>) #t (if (eq? (car ex) '<) #t
      (if (eq? (car ex) '>=) #t (eq? (car ex) '<=))))
      (string-append prefix 
        (compile-predicate (symbol->string (car ex)) (cdr ex) locs)
        suffix)
  (if (eq? (car ex) '+)        (string-append prefix (compile-append "0" "+" (cdr ex) locs) suffix)
  (if (eq? (car ex) '*)        (string-append prefix (compile-append "1" "*" (cdr ex) locs) suffix)
  (if (eq? (car ex) '-)        (string-append prefix (compile-minus "-" "-" (cdr ex) locs) suffix)
  (if (eq? (car ex) '/)        (string-append prefix (compile-minus "1/" "/" (cdr ex) locs) suffix)
  (if (eq? (car ex) 'string-append)
      (string-append prefix (compile-append "''" "+" (cdr ex) locs) suffix)
  (if (if (eq? (car ex) 'eq?) #t
        (if (eq? (car ex) '=) #t
        (if (eq? (car ex) 'eqv?) #t
        (if (eq? (car ex) 'string=?) #t (eq? (car ex) 'char=?)))))
      (string-append prefix "isEq(" (compile (cadr ex) locs) "," (compile (caddr ex) locs) ")" suffix)
  (if (eq? (car ex) 'list) (string-append prefix (compile-list (cdr ex) locs) suffix)
  (if (eq? (car ex) 'if)
;      (string-append prefix "(" (compile (cadr ex) locs)
;                     "!=false?" (compile (caddr ex) locs tail)
;                     ":" (if (null? (cdddr ex)) "null"
;                             (compile (cadddr ex) locs tail)) ")" suffix)
      (if (null? (cdddr ex))
          (compile (caddr ex) locs tail
                   (string-append prefix "((" (compile (cadr ex) locs) ")!=false?")
                   (string-append ":null)" suffix))
          (compile (cadddr ex) locs tail
                   (string-append prefix "((" (compile (cadr ex) locs)
                                  ")!=false?" (compile (caddr ex) locs tail) ":")
                   (string-append ")" suffix)))
  (if (eq? (car ex) 'define-syntax)
      (string-append prefix "e['" (symbol->string (cadr ex))
                     "']=new Syntax(e.get('" (symbol->string (caaddr ex))
                     "')," (compile-quote (cdaddr ex)) ")" suffix)
  (if (if (eq? (car ex) 'define) (symbol? (cadr ex)) #f)
      (begin (if locs (locs 'add (cadr ex)))
      (string-append prefix "e['" (symbol->string (cadr ex))
                     "']=" (compile (caddr ex) locs) suffix))
  (if (eq? (car ex) 'set!)
      (if (if locs (locs 'memq (cadr ex)) #f)
          (compile (caddr ex) locs #f
            (string-append prefix "e['" (symbol->string (cadr ex)) "']=")
            suffix)
          (compile (caddr ex) locs #f
            (string-append prefix "e.set('" (symbol->string (cadr ex)) "',")
            (string-append ")" suffix)))
  (if (eq? (car ex) 'lambda)
      (string-append prefix (compile-lambda-obj (cadr ex) (cddr ex) locs) suffix)
  (if (if (eq? (car ex) 'define) (pair? (cadr ex)) #f)
      (begin (if locs (locs 'add (caadr ex)))
      (string-append prefix "e['" (symbol->string (caadr ex))
                     "']=" (compile-lambda-obj (cdadr ex) (cddr ex) locs) suffix))
  (if (eq? (car ex) 'apply)
      (string-append prefix app "(" (compile (cadr ex) locs)
                     "," (if tail "list=" "")
                     (compile-apply-list (cddr ex) locs) ")" suffix)
  ; else function call
  (if (if tail (if (number? list-len) (>= list-len (length (cdr ex))) #f) #f)
    (string-append prefix "(" (compile-reuse (cdr ex) "list" locs) ","
                   "theTC.f=" (compile (car ex) locs) ",theTC.args=list,theTC)" suffix)
                  ; app "(" (compile (car ex) locs) ",list))" suffix)
    (compile-list (cdr ex) locs
      (string-append prefix app "(" (compile (car ex) locs) "," (if tail "list=" ""))
      (string-append ")" suffix)) 
; direct call attempts, not via Apply...
; (if tail "" "f.compiled?f.compiled(l):")
; (if tail "" "f.FType==1?f(l):")
)))))))))))))))))))))))))))))))))))))))))))))))

(define (compile-reuse lst var locs)
  (if (pair? lst)
      (string-append "(" var ".car=" (compile (car lst) locs) "),"
                     (compile-reuse (cdr lst) (string-append var ".cdr") locs))
      (string-append "(" var "=" (if (null? lst) "theNil" (compile lst locs)) ")")))

(define (compile-predicate op lst locs)
  (define s (string-append (compile (car lst) locs) op (compile (cadr lst) locs)))
  (if (null? (cddr lst)) s (string-append s "&&" (compile-predicate op (cdr lst) locs))))

(define (compile-minus one op lst locs)
  (if (null? (cdr lst))
      (string-append "(" one (compile (car lst) locs) ")")
      (compile-append "0" op lst locs)))

(define (compile-append zero op lst locs . q)
  (if (null? lst) zero
    (if (null? (cdr lst)) (compile (car lst) locs)
      (string-append (if (null? q) "(" "")
                     (compile (car lst) locs) op
                     (compile-append zero op (cdr lst) locs #t)
                     (if (null? q) ")" "")))))

(define (compile-list ex locs . tt)
  (define prefix "")
  (define suffix "")
  (if (not (null? tt))
    (begin (set! prefix (car tt))
           (set! suffix (cadr tt))))

  (if (null? ex) (string-append prefix "theNil" suffix)
  (if (pair? ex)
;      (string-append "new Pair(" (compile (car ex) locs)
;                     "," (compile-list (cdr ex) locs) ")")
      (compile-list (cdr ex) locs
        (string-append prefix "new Pair(" (compile (car ex) locs) ",")
        (string-append ")" suffix))
      (compile ex locs #f prefix suffix))))

(define (compile-quote ex . tt)
  (define prefix "")
  (define suffix "")
  (if (not (null? tt))
      (begin (set! prefix (car tt)) (set! suffix (cadr tt))))
  (if (null? ex) (string-append prefix "theNil" suffix)
  (if (symbol? ex)
      (string-append prefix "getSymbol('" (symbol->string ex) "')" suffix)
  (if (pair? ex)
      (compile-quote (cdr ex)
        (string-append prefix "new Pair(" (compile-quote (car ex)) ",")
        (string-append ")" suffix))
      (compile ex #f #f prefix suffix)))))

(define (compile-begin ex locs tail prefix suffix . q)
  (if (null? ex) (string-append prefix "null" suffix)
  (if (null? (cdr ex)) (compile (car ex) locs tail prefix suffix)
  (compile-begin (cdr ex) locs tail
    (string-append prefix (if (null? q) "(" "") (compile (car ex) locs) ",")
    (string-append (if (null? q) ")" "") suffix) #t))))

(define (compile-apply-list lst locs)
  (if (null? (cdr lst))
      (compile (car lst) locs #f "" ".ListCopy()")
      (string-append "new Pair(" (compile (car lst) locs)
                     "," (compile-apply-list (cdr lst) locs) ")")))

(define (compile-lambda-args args var)
  (if (null? args) ""
  (if (symbol? args)
      (string-append "e['" (symbol->string args) "']=" var ";")
      (string-append "e['" (symbol->string (car args))
                     "']=" var ".car;"
                     (compile-lambda-args (cdr args) (string-append var ".cdr"))))))

(define (compile-extract-children obj . c)
  (define tmp-name #f)
  (define a #f)
  (define d #f)
  (if (if (pair? obj) (not (eq? (car obj) 'quote)) #f)
      (if (eq? (car obj) 'lambda)
          (begin
            (set! tmp-name (gen-sym))
            (cons (list 'clone tmp-name)
                  (cons (cons tmp-name (cdr obj)) c)))
          (if (if (eq? (car obj) 'define) (pair? (cadr obj)) #f)
              (begin
                (set! tmp-name (gen-sym))
                (cons (list 'define (caadr obj) (list 'clone tmp-name))
                      (cons (cons tmp-name (cons (cdadr obj) (cddr obj))) c)))
              (begin
                (set! a (compile-extract-children (car obj)))
                (set! d (compile-extract-children (cdr obj)))
                (cons (cons (car a) (car d))
                      (append (cdr a) (cdr d))))))
      (cons obj c)))

(define (compile-lambda-obj args body . tt)
  (define parent-locs (if (null? tt) #f (car tt)))
  (define ex (compile-extract-children body))
  (define ll #f)
  (set! body (car ex))
  (if (not (null? (cdr ex)))
      (set! parent-locs (compile-make-locals (map+ car (cdr ex)) parent-locs)))
  (set! parent-locs (compile-make-locals args parent-locs))
  (set! ll (compile-lambda args body parent-locs))
  (string-append "new Lambda(" (compile-quote args)
    "," (if (null? (cdr body))
            (compile-quote (car body))
            (compile-quote (cons 'begin body)))
    "," (if (null? (cdr ex)) "e"
    (apply string-append "new Env(e)" (map+
           (lambda (l) (string-append
             ".With('" (symbol->string (car l)) "',"
             (compile-lambda-obj (cadr l) (cddr l) parent-locs) ")"))
        (cdr ex))))
    "," ll ")"))

(define (compile-make-locals lst parent)
  (lambda (msg v . tt)
    (define e (if (null? tt) "e" (car tt)))
    (if (eq? msg 'set!)
        (set! lst v)
      (if (eq? msg 'get)
          lst
        (if (eq? msg 'add)
            (set! lst (cons v lst))
          (if (eq? msg 'memq)
              (memq v lst)
            (if (eq? msg 'gen)
                (if (memq v lst)
                    (string-append e "['" (symbol->string v) "']")
                  (if parent
                      (parent 'gen v (string-append e ".parentEnv"))
                      (string-append "TopEnv.get('" (symbol->string v) "')"))))))))))

(define (compile-lambda args body locs)
  (compile-begin body locs #t
    (string-append "function(list){var r,e=new Env(this.env);while(true){"
                   (compile-lambda-args args "list") "r=")
    (string-append ";if(r!=theTC||r.f!=this)return r}}")))
;
(define (eval-compiled s)
  (js-eval (string-append "var e=TopEnv;" s)))
(define (compiled s)
  (js-invoke (get-prop s "compiled") "toString"))
(define (compile-lib lib)
  (let ([print
         (lambda (x)
           (display x)(display #\;)(newline))])
    (print "var e=TopEnv")
    (let ([print-compiled
           (lambda (x)
             (print (compile x)))])
      (for-each print-compiled lib))))
;
(define (server x)
  (js-invoke (js-eval "window.frames.hf") "navigate"
    (string-append "servlet/db?s=" (encode (str x)))))

