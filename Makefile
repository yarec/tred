
# Top Define
SDIR=src
ODIR=out
BOOTSTRAP=${ODIR}/bootstrap.js
LIB=${ODIR}/lib.js
SRC_= helper.js \
	  classes.js \
	  eval.js \
	  topenv.js
SRC=$(foreach i, ${SRC_}, ${SDIR}/${i})
SS_OLD=${SDIR}/lib.scm
SS=${SDIR}/lib/std.scm ${SDIR}/compiler.scm
SS=${SS_OLD}

# Main Target
app: tred
test: tred
	@node tred t/r5rs_pitfall.scm
ctest:
	@node tred -e '(compile-lib (get-file "src/lib.scm"))'

test-min: tred-min
	@node tred-min t/r5rs_pitfall.scm
bootstrap: clean ${BOOTSTRAP}
lib: clean ${LIB}
clean:
	@rm -f ${ODIR}/*
	@rm -f tred*

# Target Deps
${BOOTSTRAP}: ${SDIR}/main.js ${SRC}
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
	@node ${BOOTSTRAP} -e '(compile-lib (parse (get-file "src/lib/std.scm")))' ${SS} > $@

tred.js: ${SRC} ${LIB}
	@cat ${SRC} > $@
	@echo 'function init() {' >> $@
	@cat ${LIB} >> $@
	@echo '}' >> $@
tred: tred.js
	@echo Building tred
	@#echo '#!/usr/bin/env node' > $@
	@cat ${SDIR}/main.js > $@
	@cat $^ >> $@
	@chmod +x $@
release: tred-min tred-min.js
	@echo 'release ok'

define reduce
$(1):$(2)
	@echo Building $(1)
	@sed -e 's@function getSymbol(@function a(@g' $(2) > $(1)
	@sed -i 's@getSymbol(@a(@g' $(1)
	@#@sed -i 's@function Pair@function P@g' $(1)
	@#@sed -i 's@new Pair@P@g' $(1)
	@sed -i 's@Pair@P@g' $(1)
	@sed -i 's@theNil@N@g' $(1)
	@sed -i 's@TopEnv@T@g' $(1)
	@sed -i 's@parentEnv@PE@g' $(1)
	@sed -i 's@compile@c@g' $(1)
	@sed -i 's@Apply@A@g' $(1)
	@sed -i 's@Lambda@L@g' $(1)
	@#sed -i 's@list@l@g' $(1)
	@uglifyjs $(1) -o $(1)
	@chmod +x $(1)
endef

$(eval $(call reduce, tred-min.js, tred.js))
$(eval $(call reduce, tred-min, tred))

petite-test: tred
	petite --script t/test.nano.ss > out/petite.out
	node tred t/test.nano.ss > out/tred.out
	diff out/petite.out out/tred.out
