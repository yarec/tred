var trace = false;
var jit = false;
var sIn = false;
var sRes = false;

function objectToString(o){
    var parse = function(_o){
        var a = [], t;
        for(var p in _o){
            if(_o.hasOwnProperty(p)){
                t = _o[p];
                if(t && typeof t == "object"){
                    a[a.length]= p + ":{ " + arguments.callee(t).join(", ") + "}";
                }
                else {
                    if(typeof t == "string"){
                        a[a.length] = [ p+ ": \"" + t.toString() + "\"" ];
                    }
                    else{
                        a[a.length] = [ p+ ": " + t.toString()];
                    }
                }
            }
        }
        return a;
    }
    return "{" + parse(o).join(", ") + "}";
}

function m(t,d) {
 // window.navigate("mailto:"+t+"@"+d);
  window.location="mailto:"+t+"@"+d;
}

function R(s) {
  s='var e=TopEnv;'+s;
  s=eval(s);
  printLog( '*> ' + Str(s) );
  showRes(s);
}

function clone(x) {
  var i, r = new x.constructor;
  for(i in x) {
    if( x[i] != x.constructor.prototype[i] )
      r[i] = x[i];
  }
  return r;
}

//
// Read-Eval-Print-Loop
//

function clickEval() {
  var txt = document.getElementById('txt').value, o, res = null,time0=new Date();
  TopParser = new Parser( txt );

  while( ( o = TopParser.getObject() ) != null ) {

    if( document.getElementById('echoInp').checked )
      printLog( o.Str() );

    o = doEval( o );
    if( document.getElementById('echoRes').checked )
      printLog( '=> ' + Str(o) );
    if( o != null ) res = o;
  }
  var time1 = new Date();
  document.getElementById('time').innerHTML = 'Elapsed: ' + ((time1-time0)/1000) + ' s';
  showRes(res);
  showSymbols();
}

function showRes(res) {
  if( res != null ) {
      console.log(res.Str());
      /*
    if( document.getElementById('out') )
      document.getElementById('out').innerHTML = Html( res );
      */
  }
}

function printLog(s,no) {
    var l = no?'':"\n";
    console.log(s + l);

    /*
  document.getElementById('log').value += s + (no?'':"\n");
  if( document.getElementById('log').doScroll )
    document.getElementById('log').doScroll();
    */
}

// Need to wrap alert as calling it from Scheme
// in Firefox otherwise doesn't work
function jsAlert(text) {
  alert(text)
}

// Need to wrap settimeout as calling it from Scheme
// in Firefox otherwise doesn't work
function jsSetTimeout(f,t) {
  setTimeout(f,t)
}



//
// Interface things...
//

var buf1='';

function key1(srcElement) {
  buf1 = srcElement.value;
}

function key2(srcElement) {
  var buf2 = srcElement.value;
  var re = /(\n|\r\n){2}$/;
  if( !re.test(buf1) && re.test(buf2) ) {
    clickEval(); buf1 = buf2;
  }
}

function checkEdit(srcElement) {
  var e = srcElement, p = new Parser(e.value);
  var o = p.getObject();
  if( o instanceof Pair ) {
    e.parentElement.innerHTML = o.Html();
  }
  while( (m = p.getObject()) != null ) {
    var td = e.parentElement,
        tr = td.parentElement,
        tb = tr.parentElement,
        r0 = tb.rows[0];
    if( tb.rows.length == 1 ) { // horizontal
      var cell = tr.insertCell(td.cellIndex+1);
    } else if( r0.cells.length == 3 ) { // vertical
      r0.cells[0].rowSpan++;
      r0.cells[2].rowSpan++;
      var row = tb.insertRow(tr.rowIndex+1),
          cell = row.insertCell(0);
    } else {
      alert('Error!'); return;
    }
    cell.innerHTML = m.Html();
    cell.onclick = editCell;
    e.value = o.Str();
  }
}

function editCell(event) {
  var i, o = event.srcElement;
  if( o.children.length == 0 && // 2Do: merge subtrees...
      ! /^(\(|\)|)$/.test( o.innerHTML ) ) {
    var inp = document.createElement('input');
    inp.value = o.innerHTML;
    inp.onkeyup = function() { checkEdit(inp) };
    o.innerHTML = '';
    o.appendChild(inp);
    inp.focus();
  }
}

function hv(o) {
  var tr = o.parentElement, tbody = tr.parentElement;

  var isH = tbody.rows.length == 1 && tr.cells.length > 3;
  var isV = tbody.rows.length > 1 && tr.cells.length == 3;
  var isT = tbody.rows.length > 1 && tr.cells.length == 4;

  // 2Do: insert cell - esp. in (), move up/down, etc.

  if( isH /*tr.cells.length > 3*/ ) {
    tr.cells[0].rowSpan = tr.cells.length - 2;
    tr.cells[tr.cells.length-1].rowSpan = tr.cells.length - 2;
    //
    while( tr.cells.length > 3) {
      var cell = tr.cells[2];
/*
      tbody.insertRow().insertCell().innerHTML = cell.innerHTML;
      tr.deleteCell(2);
*/
      tr.removeChild(cell);
      tbody.insertRow().appendChild(cell);
    }
  } else if( isV ) {
    while( tbody.rows.length > 1 ) {
      var cell = tbody.rows[1].cells[0];
/*
      tr.insertCell(tr.cells.length-1).innerHTML = cell.innerHTML;
*/
      tr.insertBefore(cell,tr.cells[tr.cells.length-1]);
      tbody.deleteRow(1);
    }
  }
}

function objType(o) {
  if( isNil(o) ) return 'null';
  if( o instanceof Lambda ) return 'lambda';
  if( o instanceof Pair ) return 'list';
  if( o instanceof Char ) return 'char';
  if( o instanceof Array ) return 'vector';
  if( o instanceof Symbol ) return 'symbol';
  if( o instanceof Continuation ) return 'continuation';
  if( o instanceof Syntax ) return 'syntax';
  return typeof(o);
}

function showSymbol(s) {
  var s = ShowEnv[s]/*TopEnv.get(s)*/;
  if( s instanceof Lambda ) {
    s = new Pair( getSymbol('lambda'),
        new Pair( s.args,
        new Pair( s.body ))).Html();
  } else if( ! (s instanceof Function) ) s = Html(s);
  document.getElementById('out').innerHTML = s;
}

function showSymbols() {

    /*
  var i,j,tab = document.getElementById('symbols');
  // clear table
  while( tab.tBodies[0].rows.length > 0 ) {
    tab.tBodies[0].deleteRow(0);
  }
  //
  for( i in ShowEnv ) {
    if( i != 'parentEnv' && Env.prototype[i] == undefined ) {
      var row = tab.insertRow(0);
      var s = '<a href="javascript:showSymbol(\''+i+'\')">'+i+'<\/a>';
      row.insertCell(0).innerHTML = s;
      row.insertCell(0).innerHTML = objType(ShowEnv[i]);
    }
  }
  */
  for( i in ShowEnv ) {
    if( i != 'parentEnv' && Env.prototype[i] == undefined ) {
       console.log(s);
       console.log(objType(ShowEnv[i]));
    }
  }
}
