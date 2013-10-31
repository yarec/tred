
# Top Define
SDIR=src
ODIR=out
BOOTSTRAP=${ODIR}/bootstrap.js
LIB=${ODIR}/lib.js
SRC_= main.js \
	  helper.js \
	  classes.js \
	  eval.js \
	  topenv.js
SRC=$(foreach i, ${SRC_}, ${SDIR}/${i})
SSRC=${SDIR}/lib.scm

# Main Target
app: tred
test: tred
	@./tred t/r5rs_pitfall.scm
test-min: tred-min
	@./tred-min t/r5rs_pitfall.scm
bootstrap: clean ${BOOTSTRAP}
lib: clean ${LIB}
clean:
	@rm -f ${ODIR}/*
	@rm -f tred
	@rm -f tred-min

# Target Deps
${BOOTSTRAP}: ${SRC}
	@echo Building ${BOOTSTRAP}
	@mkdir -p ${ODIR}
	@echo '#!/usr/bin/env node'                                   > $@
	@cat $^                                                       >> $@
	@echo "function init() {"                                     >> $@
	@echo "var e=TopEnv;"                                         >> $@
	@echo "e['call/cc']=e.get('call-with-current-continuation');" >> $@
	@echo "}"                                                     >> $@
	@chmod +x $@


${LIB}: ${BOOTSTRAP} ${SDIR}/lib.scm
	@echo Building ${LIB}
	@node ${BOOTSTRAP} -e '(compile-lib)' ${SSRC} > $@

tred : ${SRC} ${LIB}
	@echo Building tred
	@echo '#!/usr/bin/env node' > $@
	@cat ${SRC} >> $@
	@echo 'function init() {' >> $@
	@cat ${LIB} >> $@
	@echo '}' >> $@
	@chmod +x $@

tred-min: tred
	@echo Building tred-min
	@sed -e 's@function getSymbol(@function a(@g' tred > tred-min
	@sed -i 's@getSymbol(@a(@g' tred-min
	@#@sed -i 's@function Pair@function P@g' tred-min
	@#@sed -i 's@new Pair@P@g' tred-min
	@sed -i 's@Pair@P@g' tred-min
	@sed -i 's@theNil@N@g' tred-min
	@sed -i 's@TopEnv@T@g' tred-min
	@sed -i 's@parentEnv@PE@g' tred-min
	@sed -i 's@compile@c@g' tred-min
	@sed -i 's@Apply@A@g' tred-min
	@sed -i 's@Lambda@L@g' tred-min
	@sed -i 's@list@l@g' tred-min
	@chmod +x tred-min
