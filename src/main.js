var fs = require('fs');
var vm = require('vm');

function includeJS(file_) {
    var code = fs.readFileSync(file_, 'utf-8');
    vm.runInThisContext(code, file_);
};

function eval_scm(code_){
    init();

    var e=TopEnv;
    var  o, res = null,time0=new Date();
    TopParser = new Parser( code_ );

    while( ( o = TopParser.getObject() ) != null ) {
        if(sIn) 
            printLog( o.Str() );
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

function eval_scm_file(file_){
    var code = fs.readFileSync(file_, 'utf-8');
    return eval_scm(code);
}

function ready(f){
    fs.exists('',f);
}

var stdio = require('stdio');
function setopts(ops){
    if(ops.trace)      { trace = true; }
    if(ops.jit)        { jit = true; }
    if(ops.showinput)  { sIn= true; }
    if(ops.showoutput) { sRes = true; }
}
var ops = stdio.getopt({
    'trace'      : {key : 't', description : 'debug options'},
    'jit'        : {key : 'j', description : 'enable jit'},
    'exp'        : {key : 'e', description : 'exec expression', args : 1 },
    'showinput'  : {key : 'i', description : 'show input'},
    'showoutput' : {key : 'o', description : 'show output'},
    'help'       : {key : 'h', description : 'show this help info'}
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
    if(ops.args[0]=='compile-lib'){
        ready(function(){
            libcode = fs.readFileSync('src/lib.scm', 'utf-8');
            trace = false;
            eval_scm('(compile-lib)');
        });
    }
    else {
        fs.exists(ops.args[0],function(exists){
            if(exists){
                setopts(ops);
                ret = eval_scm_file(ops.args[0]);
                //if(ret.constructor=='Boolean'&& ret && (ret.constructor=='Object' && ret.car!=undefined)){
                //console.log(ret);
                //}
            }
            else{
                console.log(ops.args['0']+' : not found!');
            }
        });
    }
}
