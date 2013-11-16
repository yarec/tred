
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
	@echo "(function() {"                >> $(1)
	@echo "var e=TopEnv;"                >> $(1)
	@if [ "$(2)" = "" ]; then cat ${LIB} >> $(1); \
		else echo "$(2)"                 >> $(1); fi
	@echo "}());"                        >> $(1)
endef

define head
	@echo "/**" > $(1)
	@echo " * Build with ${SI}" >> $(1)
	@echo " */" >> $(1)
endef

define reduce
$(1):$(2)
	@echo Building $(1)
	@uglifyjs $(2) -o $(1) -m sort,eval,toplevel -r 'Parser,doEval,isNil' -c unsafe
	@chmod +x $(1)
endef

define 3rd-test
$(1):
	@make -s clean && env SI=$(1) make -s test
endef

define 3rd-cp
	@echo - compiling via $(2)
	@time $(1) src/tsc.scm > $@
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
SIS=pi gsi csi gosh
$(foreach si,$(SIS),$(eval $(call 3rd-test,$(si))))

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
	$(call 3rd-cp, petite --libdirs src --script, petite)
else ifeq ($(SI),gsi)
	$(call 3rd-cp, gsi            , gambit)
else ifeq ($(SI),gosh)
	$(call 3rd-cp, gosh -I.       , gauche)
else ifeq ($(SI),csi)
	$(call 3rd-cp, csi -s         , chicken)
else
	$(error only [pi,gsi,gosh,csi] support)
endif


tred.js: ${SRC} ${LIB}
	$(call head, $@)
	@cat ${SRC} >> $@
	$(call init, $@)
tred: tred.js
	@echo Building tred
	$(call head, $@)
	@cat $^              >> $@
	@cat ${SDIR}/main.js >> $@
	@chmod +x $@
release: tred-min.js
	@echo 'release ok'

$(eval $(call reduce, tred-min.js, tred.js))
#$(eval $(call reduce, tred-min, tred))

