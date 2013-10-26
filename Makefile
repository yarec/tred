
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

# Main Target
test: tred
	@./tred t/r5rs_pitfall.scm
bootstrap: clean ${BOOTSTRAP}
lib: clean ${LIB}
clean:
	@rm -f ${ODIR}/*
	@rm -f tred

# Target Deps
${BOOTSTRAP}: ${SRC} bootstrap/lib.js
	@echo Building ${BOOTSTRAP}
	@mkdir -p ${ODIR}
	@cat $^ > $@
	@chmod +x $@

${LIB}: ${BOOTSTRAP} ${SDIR}/lib.scm
	@echo Building ${LIB}
	@node ${BOOTSTRAP} compile-lib > $@

tred : ${SRC} ${LIB}
	@echo Building tred
	@echo '#!/usr/bin/env node' > $@
	@cat ${SRC} >> $@
	@echo 'function init() {' >> $@
	@cat ${LIB} >> $@
	@echo '}' >> $@
	@chmod +x $@

