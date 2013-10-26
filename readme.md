tred
=======
Tred is a implementation of r5rs scheme similar to scheme2js. 'tred' is the abbreviation of 'treasured sword'. This project is for the purposes of study of compiler only. Original code is based on [jsscheme](http://bluishcoder.co.nz/jsscheme/). 

The goals
----
 * Self-hosting compile
 * A broswer mode repl
 * A cli mode repl 


Feathers
----
 * repl
 * TCO
 * Continuations
 * Macros
 * JIT
 * running on nodejs and broswer
 * Passes all r5rs_pitfall without jit
 * Failure on 4.2 with jit

Quick Start
----
    $ make
    $ make test
    $ ./tred t/test.cc.ss

Todo
----
 * support args
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

