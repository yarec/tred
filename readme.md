Tred
=======
Tred is a implementation of r5rs scheme similar to scheme2js. 'tred' is the abbreviation of 'treasured sword'. This project is for the purposes of study of compiler only. Original code is based on [jsscheme](http://bluishcoder.co.nz/jsscheme/). 

The goals
----
 * Self-hosting compile √
 * A broswer mode repl √
 * A cli mode repl 


Feathers
----
 * repl [online demo](http://softidy.com/tred/)
 * TCO
 * Continuations
 * Macros
 * JIT
 * running on nodejs and broswer
 * Passes all r5rs_pitfall without jit
 * Failure on 4.2 with jit

Quick Start
----
 [install node first](http://softidy.com/2013/7/26/Non-root-node-installation.html), and stdio module  
 make and test

    $ make
    $ make test
    $ node tred t/test.cc.ss
    $ node tred -e '(compile-lib (get-file "src/lib.scm"))'

 repl:

    > 1                                      => 1
    > "1"                                    => "1"
    > #\1                                    => #\1
    > (+ 1 2)                                => 3
    > (+ 1 2 3 4)                            => 10
    > (iota 10 1)                            => (1 2 3 4 5 6 7 8 9 10)
    > (apply + (iota 10 1))                  => 55
    > (map (lambda (x) (+ x 1)) (iota 10 1)) => (2 3 4 5 6 7 8 9 10 11)
    > (map + (list 1 2 3) (list 4 5 6))      => (5 7 9)
    > '(good morning)                        => (good morning)
    > `(1 ,(+ 1 1) 3)                        => (1 2 3)
    > `(1 ,@(map + '(1 3) '(2 4)) 9)         => (1 3 7 9)

 compile lib in broswer: 

    > (ajax-get "http://softidy.com/tred/lib.scm" c-lib)

Todo
----
 * support args √
 * pass all r5rs_pitfall with jit
 * I/O support, load, read-char, open-input-file, etc

Links
----
 * [Structure and Interpretation of Computer Programs](http://mitpress.mit.edu/sicp/sicp.html)
 * [JavaScript Lisp Implementations](http://ceaude.twoticketsplease.de/js-lisps.html)
 * [The Scheme Programming Language Fourth Edition R. Kent Dybvig](http://www.scheme.com/tspl4/)

Author
----
[softidy](http://about.me/softidy)  
http://softidy.com

License
----
Tred can be freely redisributed under [GPL](http://www.gnu.org/licenses/gpl.html) terms.

