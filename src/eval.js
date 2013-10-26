// Top Environment

var TopEnv = new Env();

//

function Lambda(args,body,env,compiled) {
  this.args = args;
  this.body = body;
  this.env = env;
  this.compiled = compiled;
}

Lambda.prototype.clone = function(e) {
  if( this.env.Private ) {
    e = new Env(e);
    var i; for( i in this.env ) if(e[i]==undefined) e[i]=this.env[i];
  }

  return new Lambda( this.args, this.body, e, this.compiled);
}

Lambda.prototype.Html = dumbHtml;

Lambda.prototype.Str = function() {
  return "#lambda" + (trace ? "<"+this.args.Str()
        + ',' + this.body.Str()
       // + ( trace ? ',' + this.env.Str() : '' )
        + ">" : '');
}

//
// Evaluator - new state engine (for tail/rec and call/cc)
//

function State(obj,env,cc) {
  this.obj = obj;
  this.env = env;
  this.cc = cc;
}

function stateEval(noTrace) {
  if( this.obj == null ) this.ready = true;
  if( ! this.ready ) {
    if( trace && !noTrace ) printLog( "eval: " + this.obj.Str() );
    this.ready = false;
    this.obj.Eval(this);
  }
  return this.ready;
}

function stateContinue() {
  this.cc.cont(this);
}

State.prototype.Eval = stateEval;
State.prototype.cont = stateContinue;

function Ex(s) { this.s = s; }
Ex.prototype.Str = function(){ return "#error<"+this.s+">"; }
Ex.prototype.Html = dumbHtml;

getSymbol('(').Eval = getSymbol(')').Eval = function() {
  throw new Ex('unbalanced bracket '+this.name);
}

var topCC = new Continuation(null,null,null,function(state){throw state;});

function doEval( obj, noTrans ) {
  try {
    if( obj instanceof Symbol && obj.Eval == Symbol.prototype.Eval )
      return TopEnv.get(obj.name);

    if( ! noTrans ) {
      try {
        var xformer = TopEnv.get('transform');
        if( xformer instanceof Lambda || xformer instanceof Function ) {
          var o = doEval( new Pair( xformer,
                        new Pair( new Pair( theQuote,
                                  new Pair( obj,
                                  theNil )),
                        theNil)), true );
          if( trace ) printLog( 'transformed: '+Str(o) );
          if( ! (o instanceof Ex) ) obj = o;
        }
      } catch( ex ) { }
    }

    var state = new State( obj, TopEnv, topCC );
    while( true ) {

      // Both state.Eval() and state.cont()
      // returns True if value was calculated
      // or False if continuation

      if( state.Eval(noTrans) ) {
        state.ready = false;
        state.cont();
      }
    }
  } catch(e) {
    if( e instanceof Ex )
      return e;
    else if( e instanceof State )
      return e.obj;
    else
      return new Ex(e.description); // throw e;
  }
}

function evalTrue(state) {
  state.ready = true;
}

function evalVar(state) {
  state.obj = state.env.get(this.name);
  state.ready = true;
}

// ?? Continuation

function Continuation(obj,env,cc,f) {
  this.i = 0; // for List-cont
  this.obj = obj;
  this.env = env;
  this.cc = cc;
  this.cont = f;
}

Continuation.prototype.clone = function() {
  var r = clone( this );
  if( this.cc ) r.cc = this.cc.clone();
  return r;
}

function continuePair(state) {
  this[this.i++] = state.obj;
  if( isNil(this.obj) ) {
    // apply: 1. create arg list
    var args = theNil, prev = args;
    for( var i = 1; i < this.i; i++ ) {
      var cur = new Pair( this[i], theNil );
      if( args == theNil ) args = cur; else prev.cdr = cur;
      prev = cur;
    }
    // 2. call f()
    state.env = this.env;
    state.cc = this.cc;
    state.obj = callF( this[0], args, state );
  } else {
    state.obj = this.obj.car;
    state.env = this.env;
    state.cc = this;
    this.obj = this.obj.cdr;   // 2Do: (a.b) list!!
    state.ready = false;
  }
}

Pair.prototype.ListCopy = function() {
  var o,p,r = new Pair(this.car);
  for( o = this.cdr, p=r; o instanceof Pair; p=p.cdr=new Pair(o.car), o=o.cdr );
  p.cdr = o; return r;
}

function callF( f, args, state ) {

 Again: while(true) {

  if( typeof( f ) == 'function' ) {
    state.ready = true;
    return f(args,state);

  } else if( f instanceof Lambda ) {

    if( f.compiled != false && jit ) {
      try {
        state.ready = true;
        return Apply(f,args.ListCopy() );
      } catch( e ) {
        if( e instanceof State ) {
          args = e.obj; f = e.cc;
          continue Again;
        }
        if(e!=theCannot) printLog(e instanceof Error?e.description:Str(e));
      }
    }

    // map arguments to new env variables
    state.env = new Env(f.env);

    for( var vars = f.args, vals = args;
         (vars instanceof Pair) && !isNil(vars);
         vars = vars.cdr, vals = vals.cdr ) {
      if( vars.car instanceof Symbol ) {
        state.env[ vars.car.name ] = vals.car;
      } else throw new Ex("lambda arg is not symbol");
    }
    if( vars instanceof Symbol ) {
      state.env[ vars.name ] = vals;
    } else if( ! isNil(vars) ) throw new Ex("lambda args are not symbols");

    state.ready = false;
    return f.body;

  } else if( f instanceof Continuation ) {
    state.ready = true;
    state.cc = f.clone();
    // continue - multiple values case...
    if( state.cc.cont == continuePair ) {
      while( !isNil(args.cdr) ) {
        state.cc[state.cc.i++] = args.car;
        args = args.cdr;
      }
    }
    // if( state.cc == topCC ) { }
    return args.car;

  } else {
    throw new Ex("call to non-function " + ( f && f.Str ? f.Str() : f)
                 + (trace ? " with "+args.Str() : ''));
  }
}}

function continueDefine(state) {
  state.env = this.env;
  state.cc = this.cc;
  if( this.define ) {
    state.env[this.obj.name] = state.obj;
  } else {
    state.env.set( this.obj.name, state.obj );
  }
  state.ready = true;
}

function continueBegin(state) {
  state.obj = this.obj.car;
  state.env = this.env;
  state.ready = false;
  if( isNil(this.obj.cdr) ) {
    state.cc = this.cc;
  } else {
    this.obj = this.obj.cdr;
    state.cc = this;
  }
}

function continueIf(state) {
  state.obj = state.obj ? this.obj.car : this.obj.cdr.car;
  state.env = this.env;
  state.cc = this.cc;
  state.ready = false;
}

function continueSyntax(state) {
  state.env = this.env;
  state.cc = this.cc;
  state.ready = false;
  if( trace ) printLog('rewrite: '+state.obj.Str());
}

function evalPair(state) {

  if( isNil(this) ) throw new Ex('Scheme is not Lisp, cannot eval ()');

  var f = (this.car instanceof Symbol) ? state.env.get(this.car.name) : null;

  // lambda, (define (f ...) ...)

  if( f == theLambda || (f == theDefine && (this.cdr.car instanceof Pair)) ) {

    // get function arguments and body

    var args, body;
    if( f == theLambda ) {
      args = this.cdr.car;
      body = this.cdr.cdr;
    } else {  // define
      args = this.cdr.car.cdr;
      body = this.cdr.cdr;
    }

    // create function object

    state.obj = new Lambda( args,
                            isNil(body.cdr) ? body.car :
                            new Pair( getSymbol("begin"), body ),
                            state.env );

    // define

    if( f == theDefine ) {
      state.env[ this.cdr.car.car.name ] = state.obj;
    }

    // OK, don't need to evaluate it any more

    state.ready = true;

  // define, set!

  } else if( f == theDefine || f == theSet ) {

    state.obj = this.cdr.cdr.car;
    state.cc = new Continuation( this.cdr.car, state.env, state.cc, continueDefine );
    state.cc.define = f == theDefine;
    state.ready = false; // evaluate expression first

  // begin

  } else if( f == theBegin ) {

    state.obj = this.cdr.car;
   // if( state.env != TopEnv )
   //   state.env = new Env(state.env);  // 2Do: that is wrong!!
    if( ! isNil(this.cdr.cdr) ) {
      state.cc = new Continuation( this.cdr.cdr, state.env, state.cc, continueBegin );
    }
    state.ready = false;

  // quote

  } else if( f == theQuote ) {
    state.obj = this.cdr.car;
    state.ready = true;

  // if

  } else if( f == theIf ) {
    state.obj = this.cdr.car;
    state.cc = new Continuation( this.cdr.cdr, state.env, state.cc, continueIf );
    state.ready = false;

  // define-syntax

  } else if( f == theDefineSyntax ) {

    state.env[ (state.obj = this.cdr.car).name ] = new Syntax(
      state.env.get(this.cdr.cdr.car.car.name), this.cdr.cdr.car.cdr );
    state.ready = true;

  // Syntax...

  } else if( f instanceof Syntax ) {

    state.cc = new Continuation( null, state.env, state.cc, continueSyntax );
    state.obj = callF( f.transformer, new Pair(state.obj, f.args), state );

  // (...)

  } else {
    state.obj = this.car;
    state.cc = new Continuation( this.cdr, state.env, state.cc, continuePair );
    state.ready = false;
  }
}

Nil.prototype.Eval = evalTrue;
Boolean.prototype.Eval = evalTrue;
Char.prototype.Eval = evalTrue;
Number.prototype.Eval = evalTrue;
Pair.prototype.Eval = evalPair;
String.prototype.Eval = evalTrue;
Symbol.prototype.Eval = evalVar;
Lambda.prototype.Eval = evalTrue;
Array.prototype.Eval = evalTrue;
Continuation.prototype.Eval = evalTrue;
Ex.prototype.Eval = evalTrue;
Function.prototype.Eval = evalTrue; // 2Do: throw Ex??

//
// Syntax transformers...
//

function Syntax( transformer, args ) {
  this.transformer = transformer;
  this.args = args;
}

Syntax.prototype.Eval = evalTrue;
Syntax.prototype.Html = dumbHtml;
Syntax.prototype.Str = function() { return '#syntax'; }

