MKDIR := mkdir -p
RM := rm -rf
CP := cp -r

define executable
chmod u+x $1
endef

define uninstall
$(RM) $(patsubst uninstall/%,%,$1)
endef

define install
cp env/bin/$(notdir $1) $1
$(call executable,$1)
endef

define export-file
FILE=`mktemp` && trap 'rm -f $$FILE' 0 1 2 3 15 && ( echo 'cat <<EOF'; cat "$1"; echo 'EOF') > $$FILE && export ARGUMENTS='$$@' && $(RM) $2 && . $$FILE > $2
endef

define locate-binary
$(or $(shell which $1),$(error \`$1\` is not in \`$(PATH)\`, please install it!))
endef

define merge-file
cat $1 $2 2>/dev/null | sort | uniq | grep -v -E '^\s*$$' > $1
endef

WITH_DEBUG ?=

ifneq ($(WITH_DEBUG),)
OLD_SHELL := $(SHELL)
SHELL = $(warning $(if $@, Update target $@)$(if $<, from $<)$(if $?, due to $?))$(OLD_SHELL) -x
endif

.PHONY: debug/target/%
debug/target/%: ; @$(error $* is $($*) (from $(origin $*)))

.PHONY: debug/dump/variables
debug/dump/variables:
	@$(foreach V,$(sort $(.VARIABLES)),\
	$(if $(filter-out environ% default automatic, \
	$(origin $V)),$(info $V=$(value $V))))
