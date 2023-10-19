
AUTOMAKE_OPTIONS = foreign 

EXTRA_DIST = $(TESTSUITE).at $(TESTSUITE) \
$(TESTSUITE_DMRPP_BUILDER).at $(TESTSUITER_DMRPP_BUILDER) \
$(srcdir)/package.m4 atlocal.in curl_test_macros.m4

DISTCLEANFILES = atconfig

############## Autotest follows #####################

AUTOM4TE = autom4te

TESTSUITE = $(srcdir)/testsuite
$(TESTSUITE): $(TESTSUITE).at $(srcdir)/curl_test_macros.m4 $(srcdir)/package.m4

TESTSUITE_DMRPP_BUILDER = $(srcdir)/testsuite_dmrpp_builder
$(TESTSUITE_DMRPP_BUILDER): $(TESTSUITE_DMRPP_BUILDER).at $(srcdir)/curl_test_macros.m4 \
$(srcdir)/package.m4


# TODO Check on the cache - is it really used
check-local: atconfig atlocal $(TESTSUITE)
	@echo "Run tests with an empty cache"
	$(SHELL) '$(TESTSUITE)' $(TESTSUITEFLAGS)

# -rm -rf dap_cache/*

clean-local:
	test ! -f '$(TESTSUITE)' || $(SHELL) '$(TESTSUITE)' --clean
	-rm -f $(TESTSUITE) $(TESTSUITE_DMRPP_BUILDER) $(srcdir)/package.m4

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
