// syntax keywords

TopEnv['begin'] = theBegin = getSymbol('begin');
TopEnv['quote'] = theQuote = getSymbol('quote');
TopEnv['if'] = theIf = getSymbol('if');
TopEnv['define'] = theDefine = getSymbol('define');
TopEnv['set!'] = theSet = getSymbol('set!');
TopEnv['lambda'] = theLambda = getSymbol('lambda');
TopEnv['define-syntax'] = theDefineSyntax = getSymbol('define-syntax');
TopEnv['unquote'] = getSymbol('unquote');
TopEnv['unquote-splicing'] = getSymbol('unquote-splicing');

//
// Built-in functions
//

TopEnv['+'] = function(list) {
  var result = 0;
  while( list instanceof Pair ) {
    if( typeof(list.car)=='number' ) result += list.car;
    list = list.cdr;
  }
  return result;
}

TopEnv['*'] = function(list) {
  var result = 1;
  while( ! isNil(list) ) {
    result *= list.car.valueOf();
    list = list.cdr;
  }
  return result;
}

TopEnv['-'] = function(list) {
  var result = 0, count = 0;
  while( ! isNil(list) ) {
    var o = list.car.valueOf();
    result += (count++ > 0 ? -o : o);
    list = list.cdr;
  }
  return count > 1 ? result : -result;
}

TopEnv['/'] = function(list) {
  var result = 1, count = 0;
  while( ! isNil(list) ) {
    var o = list.car.valueOf();
    result *= (count++ > 0 ? 1/o : o);
    list = list.cdr;
  }
  return count > 1 ? result : 1/result;
}

TopEnv['string-append'] = function(list) {
  var result = '';
  while( ! isNil(list) ) {
    result += list.car;
    list = list.cdr;
  }
  return result;
}

TopEnv['string'] = function(list) {
  var result = '';
  while( ! isNil(list) ) {
    result += list.car.value;
    list = list.cdr;
  }
  return result;
}

TopEnv['vector'] = function(list) {
  var result = new Array();
  while( ! isNil(list) ) {
    result[result.length] = list.car;
    list = list.cdr;
  }
  return result;
}

TopEnv['string->list'] = function(list) {
  var i, result = theNil;
  for( i = list.car.length-1; i >= 0; --i ) {
    result = new Pair( getChar(list.car.charAt(i)), result );
  }
  return result;
}

// fixed arguments

TopEnv['car'] = function(list) { return list.car.car; }
TopEnv['cdr'] = function(list) { return list.car.cdr; }
TopEnv['cons'] = function(list) { return new Pair(list.car,list.cdr.car); }

TopEnv['eval'] = function(list) { return doEval(list.car); }
TopEnv['string->symbol'] = function(list) { return getSymbol(list.car,true); }
TopEnv['symbol->string'] = function(list) { return list.car.name; }

TopEnv['encode'] = function(list) { return encodeURIComponent(list.car); }

function truncate(x) {
  return x > 0 ? Math.floor(x) : Math.ceil(x);
}

TopEnv['ceiling'] = function(list) { return Math.ceil(list.car); }
TopEnv['floor'] = function(list) { return Math.floor(list.car); }
TopEnv['truncate'] = function(list) { return truncate(list.car); }
TopEnv['sqrt'] = function(list) { return Math.sqrt(list.car); }
TopEnv['exp'] = function(list) { return Math.exp(list.car); }
TopEnv['expt'] = function(list) { return Math.pow(list.car,list.cdr.car); }
TopEnv['log'] = function(list) { return Math.log(list.car); }
TopEnv['sin'] = function(list) { return Math.sin(list.car); }
TopEnv['cos'] = function(list) { return Math.cos(list.car); }
TopEnv['asin'] = function(list) { return Math.asin(list.car); }
TopEnv['acos'] = function(list) { return Math.acos(list.car); }
TopEnv['tan'] = function(list) { return Math.tan(list.car); }

TopEnv['atan'] = function(list) {
  return isNil(list.cdr) ? Math.atan(list.car)
                         : Math.atan2(list.car,list.cdr.car);
}

TopEnv['integer?'] = function(list) { return list.car == Math.round(list.car); }
TopEnv['quotient'] = function(list) { return truncate(list.car / list.cdr.car); }
TopEnv['remainder'] = function(list) { return list.car % list.cdr.car; }
TopEnv['modulo'] = function(list) {
  var v = list.car % list.cdr.car;
  if( v && (list.car < 0) != (list.cdr.car < 0) ) v += list.cdr.car;
  return v;
}
TopEnv['round'] = function(list) { return Math.round(list.car); }

TopEnv['apply'] = function(list,state) {
  var f = list.car, cur;
  for( cur = list; !isNil(cur.cdr.cdr); cur = cur.cdr );
  cur.cdr = cur.cdr.car;
  return callF( list.car, list.cdr, state );
}

TopEnv['clone'] = function(list,state) {
  return list.car.clone(state.env);
}

function isEq(a,b) { return a==b || isNil(a)&&isNil(b); }

TopEnv['string=?'] =
TopEnv['char=?'] =
TopEnv['eqv?'] =
TopEnv['='] =
TopEnv['eq?'] = function(list) { return isEq(list.car,list.cdr.car); }

TopEnv['substring'] = function(list) {
  return list.car.substring( list.cdr.car, list.cdr.cdr.car );
}

TopEnv['string>?'] =
TopEnv['>'] = function(list) { return list.car > list.cdr.car; }
TopEnv['string<?'] =
TopEnv['<'] = function(list) { return list.car < list.cdr.car; }
TopEnv['string>=?'] =
TopEnv['>='] = function(list) { return list.car >= list.cdr.car; }
TopEnv['string<=?'] =
TopEnv['<='] = function(list) { return list.car <= list.cdr.car; }

TopEnv['char>?'] = function(list) { return list.car.value > list.cdr.car.value; }
TopEnv['char<?'] = function(list) { return list.car.value < list.cdr.car.value; }
TopEnv['char>=?'] = function(list) { return list.car.value >= list.cdr.car.value; }
TopEnv['char<=?'] = function(list) { return list.car.value <= list.cdr.car.value; }

TopEnv['char-downcase'] = function(list) { return getChar(list.car.value.toLowerCase()); }
TopEnv['char-upcase'] = function(list) { return getChar(list.car.value.toUpperCase()); }
TopEnv['string-downcase'] = function(list) { return list.car.toLowerCase(); }
TopEnv['string-upcase'] = function(list) { return list.car.toUpperCase(); }

TopEnv['char->integer'] = function(list) { return list.car.value.charCodeAt(0); }
TopEnv['integer->char'] = function(list) {
  return getChar( String.fromCharCode(list.car) );
}

TopEnv['make-string'] = function(list) {
  var s = '', i;
  for( i = 0; i < list.car; i++ ) {
    s += list.cdr.car.value;
  }
  return s;
}
TopEnv['rnd'] = function(list) { return Math.random(); }
TopEnv['string->number'] = function(list) {
  return list.cdr.car ? parseInt(list.car,list.cdr.car) : parseFloat(list.car);
}
TopEnv['number->string'] = function(list) {
  return list.cdr.car ? list.car.toString(list.cdr.car) : ''+list.car;
}

TopEnv['set-car!'] = function(list) { list.car.car = list.cdr.car; return list.car; }
TopEnv['set-cdr!'] = function(list) { list.car.cdr = list.cdr.car; return list.car; }

TopEnv['vector-length'] =
TopEnv['string-length'] = function(list) { return list.car.length; }

TopEnv['string-ref'] = function(list) {
  return getChar(list.car.charAt(list.cdr.car));
}
TopEnv['get-prop'] =
TopEnv['vector-ref'] = function(list) { return list.car[list.cdr.car]; }
TopEnv['set-prop!'] =
TopEnv['vector-set!'] = function(list) { list.car[list.cdr.car] = list.cdr.cdr.car; }
TopEnv['make-vector'] = function(list) { var v = new Array(), i;
for( i=0; i<list.car; i++ ) v[i]=list.cdr.car; return v;
}

TopEnv['str'] = function(list) { return Str(list.car); }
TopEnv['html'] = function(list) { return Html(list.car); }

/* (alert "a message") */
TopEnv['alert'] = function(list) {
  alert(list.car);
}

/* (ajax-get url function) */
TopEnv['ajax-get'] = function(list) {
  $.get(list.car, function (xml) {
    doEval (new Pair(list.cdr.car, new Pair(new Pair(theQuote, new
    Pair(xml,theNil)), theNil)), true)
  })
}

/* (set-timeout! handler timeout) */
TopEnv['set-timeout!'] = function(list) {
  setTimeout(function () {
    doEval (new Pair(list.car, theNil), true);
  }, list.cdr.car)
}

/* (set-handler! object name handler) */
TopEnv['set-handler!'] = function(list) {
  list.car[list.cdr.car] = function() {
    doEval( new Pair( list.cdr.cdr.car,
            new Pair( new Pair( theQuote,
                      new Pair( this, theNil )), theNil)), true);
  }
}
TopEnv['list-props'] = function(list) {
  var r = theNil, i;
  for( i in list.car ) r = new Pair(i,r);
  return r;
}
TopEnv['parse'] = function(list) {
  var r = theNil, c = r, p = new Parser(list.car), o;
  while( (o = p.getObject()) != null ) {
    o = new Pair(o, theNil );
    if( r == theNil ) r = o; else c.cdr = o;
    c = o;
  }
  return r;
}
TopEnv['type-of'] = function(list) { return objType(list.car); }
TopEnv['js-call'] = function(list) {
  if( isNil( list.cdr ) ) {
    return list.car();
  } else if( isNil( list.cdr.cdr ) ) {
    return list.car( list.cdr.car );
  } else if( isNil( list.cdr.cdr.cdr ) ) {
    return list.car( list.cdr.car, list.cdr.cdr.car );
  } else {
    return list.car( list.cdr.car, list.cdr.cdr.car, list.cdr.cdr.cdr.car );
  }
}
TopEnv['js-invoke'] = function(list) {
  if( isNil( list.cdr.cdr ) ) {
    return list.car[list.cdr.car]();
  } else if( isNil( list.cdr.cdr.cdr ) ) {
    return list.car[list.cdr.car]( list.cdr.cdr.car );
  } else if( isNil( list.cdr.cdr.cdr.cdr ) ) {
    return list.car[list.cdr.car]( list.cdr.cdr.car, list.cdr.cdr.cdr.car );
  } else {
    return list.car[list.cdr.car]( list.cdr.cdr.car, list.cdr.cdr.cdr.car, list.cdr.cdr.cdr.cdr.car );
  }
}

function isPair(x) { return (x instanceof Pair) && !isNil(x); }
TopEnv['pair?'] = function(list) { return isPair(list.car); }

TopEnv['boolean?'] = function(list) { return typeof(list.car)=='boolean'; }
TopEnv['string?'] = function(list) { return typeof(list.car)=='string'; }
TopEnv['number?'] = function(list) { return typeof(list.car)=='number'; }
TopEnv['null?'] = function(list) { return isNil(list.car); }
TopEnv['symbol?'] = function(list) { return list.car instanceof Symbol; }
TopEnv['syntax?'] = function(list) { return list.car instanceof Syntax; }
TopEnv['char?'] = function(list) { return list.car instanceof Char; }
TopEnv['vector?'] = function(list) { return list.car instanceof Array; }
TopEnv['procedure?'] = function(list) {
  return list.car instanceof Function ||
         list.car instanceof Lambda ||
         list.car instanceof Continuation;
}
TopEnv['lambda?'] = function(list) { return list.car instanceof Lambda; }
TopEnv['function?'] = function(list) { return list.car instanceof Function; }
TopEnv['continuation?'] = function(list) { return list.car instanceof Continuation; }

TopEnv['js-eval'] = function(list) { 
    //return eval(list.car);
    return vm.runInThisContext(list.car);
}
TopEnv['error'] = function(list) { throw new Ex(list.car); }

TopEnv['trace'] = function(list) { trace = list.car.valueOf(); }
TopEnv['read'] = function(list) { return TopParser.getObject(); }
TopEnv['write'] = function(list) { printLog(list.car.Str(),true); }
TopEnv['newline'] = function(list) { printLog('\n'); }
TopEnv['write-char'] =
TopEnv['display'] = function(list) {
  printLog( (list.car instanceof Char) ? list.car.value :
           ((typeof(list.car)=='string') ? list.car : Str(list.car)), true );
}

TopEnv['eof-object?'] =
TopEnv['js-null?'] = function(list) { return list.car == null; }

theCallCC =
TopEnv['call-with-current-continuation'] = function(list,state) {
  state.ready = false;
  return callF( list.car, new Pair( state.cc.clone(), theNil ), state );
}

var genSymBase = 0;
TopEnv['gen-sym'] = function() { return getSymbol('_'+(genSymBase++)+'_'); }



//
// Compiler...
//

var theCannot = new Ex("Lambda cannot be compiled")

function Apply(f,args) {

Again: while(true) {

  if( f instanceof Lambda ) {

    if( f.compiled == undefined ) {

     // var jitComp = TopEnv.get('compile-lambda');
      try {
        var jitComp = TopEnv.get('compile-lambda-obj');
      } catch( ee ) { throw theCannot }

      f.compiled = false;
      var expr = new Pair(jitComp,
                 new Pair(new Pair(theQuote,new Pair(f.args,theNil)),
                 new Pair(new Pair(theQuote,new Pair(
                          new Pair(f.body,theNil),theNil)),
                 theNil)));
      try {
        var res = doEval(expr,true);
        // f.compiled = eval("var tmp="+res+";tmp");
        e = f.env; 

        eval("tmp="+res);
        //var code = "tmp="+res;
        //vm.runInThisContext(code);

        f.compiled = tmp.compiled;
       // Rebuild lambda to change local (lambda())s to (clone)s
        f.body = tmp.body;
        f.env = tmp.env;
      } catch( ex ) {
        printLog( "JIT/JS/Error: " + ex.description + ", compiling:" );
        printLog( typeof(res)=='string' ? res : Str(res) );
        printLog( "for Lambda "+Str(f.args) );
        printLog( Str(f.body) );
      }
    }
    if( f.compiled == false ) {
     // Back to interpretation...
      try {
        var state = new State(null,null,topCC);
        state.obj = callF(f,args,state);
        while( true ) {
          if( state.Eval(true) ) {
            state.ready = false;
            state.cont();
          }
        }
     // throw theCannot;
      } catch(ex) {
        if( ex instanceof Ex )
          return ex;
        else if( ex instanceof State )
          return ex.obj;
        else
          return new Ex(ex.description); // throw ex;
      }
    }

    var res = f.compiled(args);
    if( res == theTC ) {
      f = res.f; args = res.args;
      continue Again;
    }
    return res;

  } else if( f instanceof Function ) {

    if( f.FType == undefined ) {
      if( /^\s*function\s*\(\s*(list|)\s*\)/.exec(f) ) f.FType=1;
     // else if( /^\s*function\s*\(list,env\)/.exec(f) ) f.FType=2;
      else f.FType=3;
    }

    if( f.FType == 1 ) return f(args);
/*
    if( f.FType == 2 ) {
      var res = f(args);
      if( res == theTC ) {
        f = res.f; args = res.args;
        continue Again;
      }
      return res;
    }
*/
    return '';
    throw new Ex("JIT: Apply to invalid function, maybe call/cc");

  } else if( f instanceof Continuation ) {
    throw new State(args,null,f); // Give it to the interpreter
  } else throw new Ex("JIT: Apply to "+Str(f));
}}

// Tail-Calls

function TC(f,args) {
  theTC.f=f; theTC.args=args;
  return theTC;
}

var theTC = new Object();

