var fs = require('fs');
var vm = require('vm');

function includeJS(file_) {
    var code = fs.readFileSync(file_, 'utf-8');
    vm.runInThisContext(code, file_);
};

function parseList(_o, _level){
    var level = _level?_level:0;
    var next_level = level +1;
    var str = '';
    for(i=0;i<level;i++){
        str += ' ';
    }
    printLog(i+'----------------');
    //console.log(objectToString(_o));
    for(var p in _o){
        //console.log('                                             '+p);
        if(_o.hasOwnProperty(p)){
            //printLog('    '+str+p +'-> ', true);
            printLog(str, true);
            o = _o[p];
            var ot = objType(o); 
            switch(ot){
                case 'list':
                    //printLog('.');
                    //printLog(objectToString(o));
                    parseList(o, next_level);
                    break;
                case 'symbol':
                case 'lambda':
                case 'char':
                case 'vector':
                case 'continuation':
                case 'syntax':
                    printLog( o.name+'--('+ot+')' );
                    break;
                case 'null':
                    printLog('nil');
                    break;
                default:
                    printLog('-: '+ objType(o));
            }
                    //printLog('==========type: '+ objType(o));
            //printLog('       '+p);
        }
    }
    //printLog(objectToString(o));
}
function eval_scm(code_){
    init();

    var e=TopEnv;
    var  o, res = null,time0=new Date();
    TopParser = new Parser( code_ );

    while( ( o = TopParser.getObject() ) != null ) {
        if(sIn) 
            printLog( o.Str() );
        if(sPL)
            parseList(o);

        o = doEval( o );

        if(sRes) 
            printLog( '=> ' + Str(o) );
        if( o != null ) res = o;
    }
    var time1 = new Date();
    if(trace)
        printLog( '//Elapsed: ' + ((time1-time0)/1000) + ' s' );
    //showRes(res);
}

function compile_scm(file_){
    libcode = fs.readFileSync(file_, 'utf-8');
    trace = false;
    eval_scm('(compile-lib)');
}

function eval_scm_file(file_){
    var code = fs.readFileSync(file_, 'utf-8');
    return eval_scm(code);
}

function ready(f){
    fs.exists('',f);
}

var stdio = require('stdio');
function setopts(ops)     {
    if(ops.trace)         { trace = true; }
    if(ops.jit)           { jit = true; }
    if(ops.showinput)     { sIn= true; }
    if(ops.showparselist) { sPL= true; }
    if(ops.showoutput)    { sRes = true; }
}
var ops = stdio.getopt({
    'trace'         : {key : 't', description : 'debug options'},
    'jit'           : {key : 'j', description : 'enable jit'},
    'exp'           : {key : 'e', description : 'exec expression', args : 1 },
    'compile'       : {key : 'c', description : 'compile scheme' },
    'showinput'     : {key : 'i', description : 'show input'},
    'showparselist' : {key : 'p', description : 'show parse list'},
    'showoutput'    : {key : 'o', description : 'show output'},
    'help'          : {key : 'h', description : 'show this help info'}
},'<File>');

if(ops.args==undefined){
    if(ops.exp){
        ready(function(){
            setopts(ops);
            ret = eval_scm(ops.exp);
        });
    }
    else{
        ops.printHelp();
    }
}
else{
    fs.exists(ops.args[0],function(exists){
        if(exists){
            if(ops.compile){
                compile_scm(ops.args[0]);
            }
            else{
                setopts(ops);
                ret = eval_scm_file(ops.args[0]);
            }
    //if(ret.constructor=='Boolean'&& ret && (ret.constructor=='Object' && ret.car!=undefined)){
    //console.log(ret);
    //}
        }
        else{
            console.log(ops.args['0']+' : not found!');
        }
    });
}
