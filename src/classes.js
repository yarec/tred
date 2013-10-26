
//
// Classes...
//

// Pair - List construction block

function Pair( car, cdr ) {
  this.car = car;
  this.cdr = cdr;
}

function isNil(x) {
  return x == theNil || x == null || ( (x instanceof Pair) &&
         x.car == null && x.cdr == null );
}

function Nil() { }
var theNil = new Nil();

Nil.prototype.Str = function() { return '()'; }
Nil.prototype.Html = dumbHtml;
Nil.prototype.ListCopy = function() { return this; }

// Char class constructor - since we don't have Char type in JS
// 2Do: Chat = String with .isChar=true ??

function Char(c) {
  Chars[ this.value = c ] = this;
}

// Symbol class constructor - to distinguish it from String

function Symbol(s) {
  Symbols[ this.name = s ] = this;
}

var Symbols = new Object();
var Chars = new Object();

function getSymbol(name,leaveCase) {
  if( ! leaveCase ) name = name.toLowerCase(); // case-insensitive symbols!
  if( Symbols[name] != undefined ) {
    return Symbols[name];
  }
  return new Symbol(name);
}

function getChar(c) {
  if( Chars[c] != undefined ) {
    return Chars[c];
  }
  return new Char(c);
}

//
// Parser
//

// Tokenizer

function tokenize(txt) {
  var tokens = new Array(), oldTxt=null;
  while( txt != "" && oldTxt != txt ) {
    oldTxt = txt;
    txt = txt.replace( /^\s*(;[^\r\n]*(\r|\n|$)|#\\[^\w]|#?(\(|\[|{)|\)|\]|}|\'|`|,@|,|\"(\\(.|$)|[^\"\\])*(\"|$)|[^\s()\[\]{}]+)/,
      function($0,$1) {
        if( $1.charAt(0) != ';' ) tokens[tokens.length]=$1;
        return "";
      } );
  }
  return tokens;
}

// Parser class constructor

function Parser(txt) {
  this.tokens = tokenize(txt);
  this.i = 0;
}

// get list items until ')'

Parser.prototype.getList = function( close ) {
  var list = theNil, prev = list;
  while( this.i < this.tokens.length ) {
    if( this.tokens[ this.i ] == ')' ||
        this.tokens[ this.i ] == ']' ||
        this.tokens[ this.i ] == '}' ) {
      this.i++; break;
    }

    if( this.tokens[ this.i ] == '.' ) {
      this.i++;
      var o = this.getObject();
      if( o != null && list != theNil ) {
        prev.cdr = o;
      }
    } else {
      var cur = new Pair( this.getObject(), theNil );
      if( list == theNil ) list = cur;
      else prev.cdr = cur;
      prev = cur;
    }
  }
  return list;
}

Parser.prototype.getVector = function( close ) {
  var arr = new Array();
  while( this.i < this.tokens.length ) {
    if( this.tokens[ this.i ] == ')' ||
        this.tokens[ this.i ] == ']' ||
        this.tokens[ this.i ] == '}' ) { this.i++; break; }
    arr[ arr.length ] = this.getObject();
  }
  return arr;
}

// get object

Parser.prototype.getObject = function() {
  if( this.i >= this.tokens.length ) return null;
  var t = this.tokens[ this.i++ ];

 // if( t == ')' ) return null;

  var s = t == "'" ? 'quote' :
          t == "`" ? 'quasiquote' :
          t == "," ? 'unquote' :
          t == ",@" ? 'unquote-splicing' : false;
  if( s || t == '(' || t == '#(' ||
           t == '[' || t == '#[' ||
           t == '{' || t == '#{' ) {
    return s ? new Pair( getSymbol(s),
               new Pair( this.getObject(),
               theNil ))
             : (t=='(' || t=='[' || t=='{') ? this.getList(t) : this.getVector(t);
  } else {

    var n;
    if( /^#x[0-9a-z]+$/i.test(t) ) {  // #x... Hex
      n = new Number('0x'+t.substring(2,t.length) );
    } else if( /^#d[0-9\.]+$/i.test(t) ) {  // #d... Decimal
      n = new Number( t.substring(2,t.length) );
    } else n = new Number(t);  // use constrictor as parser

    if( ! isNaN(n) ) {
      return n.valueOf();
    } else if( t == '#f' || t == '#F' ) {
      return false;
    } else if( t == '#t' || t == '#T' ) {
      return true;
    } else if( t.toLowerCase() == '#\\newline' ) {
      return getChar('\n');
    } else if( t.toLowerCase() == '#\\space' ) {
      return getChar(' ');
    } else if( /^#\\.$/.test(t) ) {
      return getChar( t.charAt(2) );
    } else if( /^\"(\\(.|$)|[^\"\\])*\"?$/.test(t) ) {
       return t.replace( /^\"|\\(.|$)|\"$/g, function($0,$1) {
           return $1 ? $1 : '';
         } );
    } else return getSymbol(t);  // 2Do: validate !!
  }
}

//
// Printers
//

Boolean.prototype.Str = function () {
  return this.valueOf() ? '#t' : '#f';
}

Char.prototype.Str = function () {
  if( this.value == ' ' ) return '#\\space';
  if( this.value == '\n' ) return '#\\newline';
  return '#\\'+this.value;
}

Number.prototype.Str = function () {
  return this.toString();
}

Pair.prototype.Str = function () {
  var s = '';
  for( var o = this; o != null && o instanceof Pair && (o.car != null || o.cdr != null); o = o.cdr ) {
    if( o.car != null ) {
      if(s) s += ' ';
      s += Str(o.car);
    }
  }
  if( o != theNil && o != null && !( o instanceof Pair ) )
    s += ' . ' + Str(o);
  return '('+s+')';
}

String.prototype.Str = function () {
  return '"'+this.replace(/\\|\"/g,function($0){return'\\'+$0;})+'"';
}

Symbol.prototype.Str = function () {
  return this.name;
}

Function.prototype.Str = function () {
  return '#primitive' + (trace ? '<'+this+'>' : '');
}

function Str(obj) {
  if( obj == null ) return "#null";
  if( obj.Str ) return obj.Str();
  var c = obj.constructor, r;
  if( c ) {
    if( r = /^\s*function\s+(\w+)\(/.exec(c) ) c = r[1];
    return '#obj<'+c+'>';
  }
  return '#<'+obj+'>';
}

function Html(obj) {
  if( obj == null ) return "#null";
  if( obj.Html ) return obj.Html();
  return escapeHTML( '#obj<'+obj+'>' );
}

Array.prototype.Str = function () {
  var s='',i;
  for( i=0; i<this.length; i++ ) {
    if( s != '' ) s += ' ';
    s += Str( this[i] );
  }
  return '#('+s+')';
}

Continuation.prototype.Str = function () {
  return "#continuation";
}

// HTML output

function escapeHTML(s) {
  return s.replace( /(&)|(<)|(>)/g,
    function($0,$1,$2,$3) {
      return $1 ? '&amp;' : $2 ? '&lt;' : '&gt;';
    } );
}

function dumbHtml() {
  return escapeHTML( this.Str() );
}

function pairHtml() {
  var s1='',s2='', i, cells = new Array(), allSimple=true, firstSymbol=false;
  for( var o = this; o instanceof Pair && !isNil(o); o = o.cdr ) {
    if( o.car != null ) {
      if( cells.length == 0 )
        firstSymbol = o.car instanceof Symbol && o.car != theBegin;
      allSimple = allSimple && !(o.car instanceof Pair) &&
                               !(o.car instanceof Array);
      cells[cells.length] = Html(o.car);
    }
  }
  if( o != theNil && o != null && !( o instanceof Pair ) ) {
    cells[cells.length] = '.';
    allSimple = allSimple && !(o instanceof Array);
    cells[cells.length] = Html(o);
    if( firstSymbol && cells.length == 3 ) allSimple = true;
  }

  var rowSpan = allSimple ? 1 : firstSymbol ? cells.length-1 : cells.length;
  rowSpan = rowSpan>1 ? ' rowSpan='+rowSpan : '';

  var edit = ''; // " onClick=editCell()"
  for( i=0; i<cells.length; i++ ) {
    if( allSimple || i<1 || (i<2 && firstSymbol) ) {
      s1 += "<td"+(cells[i]=='.'?'':edit)
         + (i==0&&firstSymbol ? ' valign=top'+rowSpan : '')
         + ">" + cells[i] + "<\/td>";
    } else {
      s2 += "<tr><td"+(cells[i]=='.'?'':edit)
         + ">" + cells[i] + "<\/td><\/tr>";
    }
  }

  return '<table border=0 cellspacing=1 cellpadding=4>'
       + '<tr><td valign=top'+rowSpan+'>(<\/td>'
       + s1 + '<td valign=bottom'+rowSpan+'>)<\/td><\/tr>' + s2 + '<\/table>';
//  onClick=hv(this)
}

Boolean.prototype.Html = dumbHtml;
Char.prototype.Html = dumbHtml;
Number.prototype.Html = dumbHtml;
Pair.prototype.Html = pairHtml;
String.prototype.Html = dumbHtml;
Symbol.prototype.Html = dumbHtml;
Function.prototype.Html = dumbHtml;
Array.prototype.Html = dumbHtml;
Continuation.prototype.Html = dumbHtml;

//
// Environment
//

function Env(parent) {
  this.parentEnv = parent;
}

Env.prototype.get = function(name) {
  var v = this[name]; if( v != undefined ) return v;
  for( var o = this.parentEnv; o; o = o.parentEnv ) {
    v = o[name]; if( v != undefined ) return v;
  }
 // if( typeof(v) == 'undefined' ) {
 //   if( this.parentEnv ) return this.parentEnv.get(name); else
    throw new Ex("unbound symbol "+name);
 // } else return v;
}

Env.prototype.set = function( name, value ) {
  for( var o=this; o; o=o.parentEnv )
    if( o[name] != undefined ) return o[name]=value;
 // if( typeof(this[name]) == 'undefined' ) {
 //   if( this.parentEnv ) this.parentEnv.set(name,value); else
    throw new Ex("cannot set! unbound symbol "+name);
 // } else this[name] = value;
}

Env.prototype.Str = function() {
  var s = '',i;
  for( i in this ) {
    if( ! Env.prototype[i] && this[i]!=TopEnv ) {
      if( s != '' ) s += ',';
      var v = this[i];
      s += i + '=' + ( v instanceof Lambda ? '#lambda' :
                       typeof(v) == 'function' ? '#js' :
                       v ? v.Str() : v );
    }
  }
  return '['+s+']';
}

Env.prototype.With = function(a,v) { this[a]=v; this.Private=true; return this; }

