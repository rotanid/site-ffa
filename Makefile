GLUON_BUILD_DIR := gluon-build
GLUON_GIT_URL := https://github.com/tecff/gluon.git
GLUON_GIT_REF := 732ebe7d4cd67cf00164b5237cc8c699611b08b7

SECRET_KEY_FILE ?= ${HOME}/.gluon-secret-key

GLUON_TARGETS ?= \
	ar71xx-generic \
	ar71xx-mikrotik \
	ar71xx-nand \
	ar71xx-tiny \
	brcm2708-bcm2708 \
	brcm2708-bcm2709 \
	ipq806x \
	mpc85xx-generic \
	mvebu \
	ramips-mt7620 \
	ramips-mt7621 \
	ramips-mt7628 \
	ramips-rt305x \
	sunxi \
	x86-64 \
	x86-generic \
	x86-geode

GLUON_RELEASE := $(shell git describe --tags 2>/dev/null)
ifneq (,$(shell git describe --exact-match --tags 2>/dev/null))
  GLUON_BRANCH := stable
else
  GLUON_BRANCH := experimental
endif

MAKE_PID := $(shell echo $$PPID)
JOB_FLAG := $(filter -j%, $(subst -j ,-j,$(shell ps T | grep "^\s*$(MAKE_PID).*$(MAKE)")))
JOBS     := $(subst -j,,${JOB_FLAG})
ifeq ($(strip ${JOBS}),)
    JOBS := $(shell cat /proc/cpuinfo | grep processor | wc -l)
endif

GLUON_MAKEFLAGS := -j${JOBS} -C ${GLUON_BUILD_DIR} \
			GLUON_RELEASE=${GLUON_RELEASE} \
			GLUON_BRANCH=${GLUON_BRANCH}

all: info manifest

info:
	@echo
	@echo '#########################'
	@echo '# TECFF Firmware build'
	@echo '# Building release ${GLUON_RELEASE} for branch ${GLUON_BRANCH}'
	@echo

build: gluon-prepare
	+for target in ${GLUON_TARGETS}; do \
		echo ""Building target $$target""; \
		$(MAKE) ${GLUON_MAKEFLAGS} GLUON_TARGET="$$target"; \
	done

manifest: build
	$(MAKE) ${GLUON_MAKEFLAGS} manifest
	mv ${GLUON_BUILD_DIR}/output .

sign: manifest
	${GLUON_BUILD_DIR}/contrib/sign.sh ${SECRET_KEY_FILE} output/images/sysupgrade/${GLUON_BRANCH}.manifest

${GLUON_BUILD_DIR}:
	git clone ${GLUON_GIT_URL} ${GLUON_BUILD_DIR}

gluon-prepare: output-clean ${GLUON_BUILD_DIR}
	(cd ${GLUON_BUILD_DIR} \
	  && git remote set-url origin ${GLUON_GIT_URL} \
	  && git fetch origin \
	  && git checkout -q ${GLUON_GIT_REF})
	ln -sfT .. ${GLUON_BUILD_DIR}/site
	$(MAKE) ${GLUON_MAKEFLAGS} update

gluon-clean:
	rm -rf ${GLUON_BUILD_DIR}

output-clean:
	rm -rf output

clean: gluon-clean output-clean
