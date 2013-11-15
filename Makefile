
# Top Define
ifeq ($(strip $(SI)), )
SI=nosi
endif
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

CODE_CALLCC=e['call/cc']=e.get('call-with-current-continuation');
CODE_CLIB=(compile-lib (parse (get-file "src/lib.scm")))

# Func Defs
define init
	@echo "function init() {" >> $(1)
	@echo "var e=TopEnv;"     >> $(1)
	@if [ "$(2)" = "" ]; then   \
		cat ${LIB}     >> $(1); \
		else echo "$(2)" >> $(1); \
		fi
	@echo "}"                 >> $(1)
endef

define head
	@echo "/**" > $(1)
	@echo " * Build with ${SI}" >> $(1)
	@echo " */" >> $(1)
endef

define reduce
$(1):$(2)
	@echo Building $(1)
	@#uglifyjs $(2) -o $(1)
	@node_modules/packer/cli.js -b -i $(2) -o $(1)
	@chmod +x $(1)
endef

# Main Target
app: tred
test: tred
	@node tred     t/r5rs_pitfall.scm
test-min: tred-min
	@node tred-min t/r5rs_pitfall.scm
ctest: tred
	@node tred     -e '$(CODE_CLIB)'
rctest: release
	@node tred-min -e '$(CODE_CLIB)'
petite-test: tred
	petite --script t/test.nano.ss > out/petite.out
	node tred t/test.nano.ss > out/tred.out
	diff out/petite.out out/tred.out

bootstrap: clean ${BOOTSTRAP}
lib: clean ${LIB}
clean:
	@rm -f ${ODIR}/*
	@rm -f tred*

# Target Deps
${BOOTSTRAP}: ${SDIR}/main.js ${SRC}
	@echo Building ${BOOTSTRAP}
	@mkdir -p ${ODIR}
	@echo '#!/usr/bin/env node' > $@
	@cat  $^ >> $@
	$(call init, $@, $(CODE_CALLCC))
	@chmod +x $@

${LIB}: ${BOOTSTRAP} ${SDIR}/lib.scm
	@echo Building with $(SI) ${LIB}
ifeq ($(SI),nosi)
	@echo - use bootstrap.js [ ${SS_OLD} ]
	@node ${BOOTSTRAP} -e '$(CODE_CLIB)' ${SS_OLD} >> $@
else ifeq ($(SI),pi)
	@echo - use petite compiling  [ ${SS} ]
	@petite --script src/tsc.scm > $@
else ifeq ($(SI),gsi)
	@echo - use gambit compiling  [ ${SS} ]
	@gsi src/tsc.scm > $@
else
	$(error only [pi, gsi] support)
endif


tred.js: ${SRC} ${LIB}
	$(call head, $@)
	@cat ${SRC} >> $@
	$(call init, $@)
tred: tred.js
	@echo Building tred
	@#echo '#!/usr/bin/env node' > $@
	$(call head, $@)
	@cat ${SDIR}/main.js >> $@
	@cat $^              >> $@
	@chmod +x $@
release: tred-min.js
	@echo 'release ok'

$(eval $(call reduce, tred-min.js, tred.js))
#$(eval $(call reduce, tred-min, tred))

