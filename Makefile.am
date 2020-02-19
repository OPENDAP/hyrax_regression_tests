
AUTOMAKE_OPTIONS = foreign 

# TODO Remove old bes.conf stuff

# noinst_DATA = bes.conf

# CLEANFILES = bes.conf

EXTRA_DIST = $(TESTSUITE).at $(TESTSUITE) \
$(srcdir)/package.m4 atlocal.in curl_test_macros.m4

# bes.conf.in

DISTCLEANFILES = atconfig

# Build the bes.conf used for testing so that the value substituted for
# @abs_top_srcdir@ does not contain '../'. This happens when using 
# configure's value for the parameter when running the distcheck target.
bes.conf: bes.conf.in $(top_srcdir)/configure.ac
	@clean_abs_top_srcdir=`echo ${abs_top_srcdir} | sed 's/\(.*\)\/\(.[^\/]*\)\/\.\./\1/g'`; \
	sed -e "s%[@]abs_top_srcdir[@]%$$clean_abs_top_srcdir%" \
		-e "s%[@]abs_top_builddir[@]%${abs_top_builddir}%" $< > bes.conf

############## Autotest follows #####################

AUTOM4TE = autom4te

TESTSUITE = $(srcdir)/testsuite

$(TESTSUITE): $(TESTSUITE).at $(srcdir)/curl_test_macros.m4 $(srcdir)/package.m4

# TODO Check on the cache - is it really used
check-local: atconfig atlocal $(TESTSUITE)
	@echo "Run tests with an empty cache"
	$(SHELL) '$(TESTSUITE)' $(TESTSUITEFLAGS)
	-rm -rf dap_cache/*

clean-local:
	test ! -f '$(TESTSUITE)' || $(SHELL) '$(TESTSUITE)' --clean
	-rm -f $(TESTSUITE) $(srcdir)/package.m4

AUTOTEST = $(AUTOM4TE) --language=autotest

% : %.at 
	$(AUTOTEST) -I '$(srcdir)' -o $@ $@.at

# The `:;' works around a Bash 3.2 bug when the output is not writeable.
$(srcdir)/package.m4: $(top_srcdir)/configure.ac
	:;{ \
	echo '# Signature of the current package.' && \
	echo 'm4_define([AT_PACKAGE_NAME],      [@PACKAGE_NAME@])' && \
	echo 'm4_define([AT_PACKAGE_TARNAME],   [@PACKAGE_TARNAME@])' && \
	echo 'm4_define([AT_PACKAGE_VERSION],   [@PACKAGE_VERSION@])' && \
	echo 'm4_define([AT_PACKAGE_STRING],    [@PACKAGE_STRING@])' && \
	echo 'm4_define([AT_PACKAGE_BUGREPORT], [@PACKAGE_BUGREPORT@])'; \
	} >'$(srcdir)/package.m4'
