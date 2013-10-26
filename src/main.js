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

var argv = process.argv.splice(2);
if(argv.length==0){
    console.log('filename must given!');
}
else{
    if(argv[0]=='compile-lib'){
        fs.exists(argv[0],function(exists){
            libcode = fs.readFileSync('src/lib.scm', 'utf-8');
            trace = false;
            eval_scm('(compile-lib)');
        });
    }
    else {
        fs.exists(argv[0],function(exists){
            if(exists){
                ret = eval_scm_file(argv[0]);
                //if(ret.constructor=='Boolean'&& ret && (ret.constructor=='Object' && ret.car!=undefined)){
                //console.log(ret);
                //}
            }
            else{
                console.log(argv['0']+' : not found!');
            }
        });
    }
}
