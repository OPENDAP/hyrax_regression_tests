#
# These macros represent the best way I've found to incorporate building baselines
# into autotest testsuites. Until Hyrax/BES has a comprehensive way to make these
# kinds of tests - using a single set of macros from one source, copy this into
# the places it's needed and hack. If substantial changes are needed, try to copy
# them back into this file. jhrg 12/14/15 
#
# See below for the macros to use - do not use the macros that start with an 
# underscore.
AT_ARG_OPTION_ARG([baselines],
    [--baselines=yes|no   Build the baseline file for parser test 'arg'],
    [echo "baselines set to $at_arg_baselines";
     baselines=$at_arg_baselines],[baselines=])

# Run some tests conditionally, depending on how the BES was built. By default,
# assume we are testing against a developer build of the BES.

AT_ARG_OPTION_ARG([besdev],
    [--besdev=yes|no   Was the BES built using --enable-developer?],
    [echo "besdev set to $at_arg_besdev"; besdev=$at_arg_besdev],
    [besdev=no])

AT_ARG_OPTION_ARG([dap_service],
    [--dap_service=dap_service_url Run tests against the DAP service located at the specified endpoint URL. (default: http://localhost:8080/opendap/hyrax)],
    [echo "dap_service set to $at_arg_dap_service"; DAP_SERVICE=$at_arg_dap_service],
    [echo "dap_service default http://localhost:8080/opendap/hyrax"; DAP_SERVICE=http://localhost:8080/opendap/hyrax])

dnl We need to remove the Date: HTTP header from both baselines and responses
dnl since it varies over time.

m4_define([REMOVE_DATE_HEADER], [dnl
    sed 's/^Date:.*$/Date: REMOVED/g' < $1 > $1.sed
    cp $1.sed $1
])

dnl The above macro modified to edit the '<h3>OPeNDAP Hyrax (Not.A.Release)' issue
dnl so that whatever appears in the parens is moot.

m4_define([PATCH_HYRAX_RELEASE], [dnl
    sed 's@OPeNDAP Hyrax (.*)\(.*\)@OPeNDAP Hyrax (Not.A.Release)\1@g' < $1 > $1.sed
    mv $1.sed $1
])

dnl When we made these tests independent of the server host, we had to make sure
dnl the host name in the baselines was replaced with a consistent symbol and make
dnl that symbol was, in turn, used in the response text compared to the baselines.

m4_define([PATCH_SERVER_NAME], [dnl
    sed "s+$DAP_SERVICE+@DAP_SERVICE@+g" < $1 > $1.sed
    mv $1.sed $1
])

#######################################################################################
#
#   CURL TESTS

#--------------------------------------------------------------------------------------
#
# Basic test using diff  Response output should be text!!
#
# Usage: AT_CURL_RESPONSE_TEST(test, [xfail|xpass])
# The baseline for 'test' must be in 'test.baseline'
# If arg #2 is not given, assume xpass

m4_define([AT_CURL_RESPONSE_TEST], [dnl

    AT_SETUP([curl $1])
    AT_KEYWORDS([text])

    input=$abs_srcdir/$1
    baseline=$abs_srcdir/$1.baseline

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([sed "s+@DAP_SERVICE@+$DAP_SERVICE+g" $input | curl -n -c cookies_file -b cookies_file -L -K -], [0], [stdout])
        PATCH_HYRAX_RELEASE([stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([mv stdout $baseline.tmp])
        ],
        [
        AT_CHECK([sed "s+@DAP_SERVICE@+$DAP_SERVICE+g" $input | curl -n -c cookies_file -b cookies_file -L -K -], [0], [stdout])
	    PATCH_HYRAX_RELEASE([stdout])
	    PATCH_SERVER_NAME([stdout])
        AT_CHECK([diff -b -B $baseline stdout], [0], [ignore])
        AT_XFAIL_IF([test "$2" = "xfail"])
        ])

    AT_CLEANUP
])

#--------------------------------------------------------------------------------------
#
# DAP2 Data response test
#
# Usage: AT_CURL_DAP2_DATA_RESPONSE_TEST(test, [xfail|xpass])
# The baseline for 'test' must be in 'test.baseline'
# If arg #2 is not given, assume xpass

m4_define([AT_CURL_DAP2_DATA_RESPONSE_TEST],  [dnl

    AT_SETUP([curl $1])
    AT_KEYWORDS([dods])

    input=$abs_srcdir/$1
    baseline=$abs_srcdir/$1.baseline

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([sed "s+@DAP_SERVICE@+$DAP_SERVICE+g" $input | curl -n -c cookies_file -b cookies_file -L -K - | getdap -Ms -], [0], [stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([mv stdout $baseline.tmp])
        ],
        [
        AT_CHECK([sed "s+@DAP_SERVICE@+$DAP_SERVICE+g" $input | curl -n -c cookies_file -b cookies_file -L -K - | getdap -Ms -], [0], [stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([diff -b -B $baseline stdout], [0], [ignore])
        AT_XFAIL_IF([test "$2" = "xfail"])
        ])

    AT_CLEANUP
])

#--------------------------------------------------------------------------------------
#
# DAP4 Data response test
#
# Usage: AT_CURL_DAP4_DATA_RESPONSE_TEST(test, [xfail|xpass])
# The baseline for 'test' must be in 'test.baseline'
# If arg #2 is not given, assume xpass

m4_define([AT_CURL_DAP4_DATA_RESPONSE_TEST],  [dnl

    AT_SETUP([CURL $1])
    AT_KEYWORDS([dap])

    input=$abs_srcdir/$1
    baseline=$abs_srcdir/$1.baseline

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([sed "s+@DAP_SERVICE@+$DAP_SERVICE+g" $input | curl -n -c cookies_file -b cookies_file -L -K - | getdap4 -D -M -s -], [0], [stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([mv stdout $baseline.tmp])
        ],
        [
        AT_CHECK([sed "s+@DAP_SERVICE@+$DAP_SERVICE+g" $input | curl -n -c cookies_file -b cookies_file -L -K - | getdap4 -D -M -s -], [0], [stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([diff -b -B $baseline stdout], [0], [ignore])
        AT_XFAIL_IF([test "$2" = "xfail"])
        ])

    AT_CLEANUP
])

#--------------------------------------------------------------------------------------
#
# ASCII Regex test
#
# Usage: AT_CURL_RESPONSE_PATTERN_MATCH_TEST(test, [xfail|xpass])
# The baseline for 'test' must be in 'test.baseline'
# If arg #2 is not given, assume xpass

m4_define([AT_CURL_RESPONSE_PATTERN_MATCH_TEST], [dnl

    AT_SETUP([curl $1])
    AT_KEYWORDS([pattern])

    input=$abs_srcdir/$1
    baseline=$abs_srcdir/$1.baseline

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([sed "s+@DAP_SERVICE@+$DAP_SERVICE+g" $input | curl -n -c cookies_file -b cookies_file -L -K -], [0], [stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([mv stdout $baseline.tmp])
        ],
        [
        AT_CHECK([sed "s+@DAP_SERVICE@+$DAP_SERVICE+g" $input | curl -n -c cookies_file -b cookies_file -L -K -], [0], [stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([grep -f $baseline stdout], [0], [ignore])
        AT_XFAIL_IF([test "$2" = "xfail"])
        ])

    AT_CLEANUP
])

#--------------------------------------------------------------------------------------
#
# ASCII Compare PLUS Check HTTP Header using REGEX
# The http_header baseline MUST be edited to make a correct regular expression
#
# Usage: AT_CURL_RESPONSE_AND_HTTP_HEADER_TEST(test, [xfail|xpass])
# The baseline for 'test' must be in 'test.baseline'
# If arg #2 is not given, assume xpass

m4_define([AT_CURL_RESPONSE_AND_HTTP_HEADER_TEST], [dnl

    AT_SETUP([curl $1])
    AT_KEYWORDS([header])

    input=$abs_srcdir/$1
    baseline=$abs_srcdir/$1.baseline

    dnl Made this use the PID because parallel tests might overwrite data if using the
    dnl same file name. I'm not sure autotest is smart enough to recognize that situation
    dnl for an arbitrary file. It does seem to delete the file.
    http_header=http_header$$

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([sed "s+@DAP_SERVICE@+$DAP_SERVICE+g" $input | curl -n -c cookies_file -b cookies_file -L -D $http_header -K -], [0], [stdout])
        dnl REMOVE_DATE_HEADER([$http_header])
        AT_CHECK([mv stdout $baseline.tmp])
        dnl Initialize the $baseline.http_header.tmp file with cntl-c, then put the first
        dnl 'header' (HTTP/1.1 <code>) in there, substituting '\.' for '.'
        AT_CHECK([head -1 $http_header | tr -d '\r' > $input.http_header.tmp])
        dnl AT_CHECK([echo "^\c" > $baseline.http_header.tmp; head -1 $http_header | sed "s/\./\\\./g" >> $baseline.http_header.tmp])
        ],
        [
        AT_CHECK([sed "s+@DAP_SERVICE@+$DAP_SERVICE+g" $input | curl -n -c cookies_file -b cookies_file -L -D $http_header -K -], [0], [stdout])
        dnl REMOVE_DATE_HEADER([$http_header])
        AT_CHECK([diff -b -B $baseline stdout], [0], [ignore])
        AT_CHECK([grep -f $input.http_header $http_header], [0], [ignore])
        AT_XFAIL_IF([test "$2" = "xfail"])
        ])

    AT_CLEANUP
])

#--------------------------------------------------------------------------------------
#
# Check HTTP Header using REGEX
# The http_header baseline MUST be edited to make a correct regular expression
#
# Usage: AT_CURL_HTTP_HEADER_TEST(test, [xfail|xpass])
# This test does not compare a baseline, like the others but builds a 'baseline'
# using the HTTP response information in the response headers.
# If arg #2 is not given, assume xpass

m4_define([AT_CURL_HTTP_HEADER_TEST], [dnl

    AT_SETUP([curl $1])
    AT_KEYWORDS([html])

    input=$abs_srcdir/$1

    dnl Made this use the PID because parallel tests might overwrite data if using the
    dnl same file name. I'm not sure autotest is smart enough to recognize that situation
    dnl for an arbitrary file. It does seem to delete the file.
    http_header=http_header$$

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([sed "s+@DAP_SERVICE@+$DAP_SERVICE+g" $input | curl -n -c cookies_file -b cookies_file -L -D $http_header -K - > /dev/null], [0], [ignore])

        dnl The first line of the headers is the HTTP return status.
        dnl Remove the CR from the CRLF pair so that grep can use the line for a string/pattern match.
        dnl NB: sed on OSX does not recognize \r, so use tr to remove the CR character. jhrg 2/20/20
        AT_CHECK([head -1 $http_header | tr -d '\r' > $input.http_header.tmp])
        ],
        [
        AT_CHECK([sed "s+@DAP_SERVICE@+$DAP_SERVICE+g" $input | curl -n -c cookies_file -b cookies_file -L -D $http_header -K -], [0], [stdout])

        dnl -F: test strings, not patterns. This test just looks for the HTTP response code.
        AT_CHECK([grep -F -f $input.http_header $http_header], [0], [ignore])

        dnl Now check the baseline if it exists. These baselines contain a list of
        dnl patterns that must be present. They have to be written by hand.
        dnl
        dnl FIXME This does not work. Close, but not working yet.
        dnl
        AS_IF([test -f $input.lines],
        [
         AT_CHECK([test `cat $input.lines | wc -l` -eq `grep -f $input.lines stdout | wc -l`], [0], [ignore])
        ])
        AT_XFAIL_IF([test "$2" = "xfail"])
        ])

    AT_CLEANUP
])


#--------------------------------------------------------------------------------------
# 
# Alternate version of the AT_CURL_HEADER_AND_RESPONSE_TEST for the forced-errors tests
# ASCII Compare PLUS Check HTTP Header using REGEX
# The http_header baseline MUST be edited to make a correct regular expression
#
# Usage: AT_CURL_RESPONSE_AND_HTTP_HEADER_TEST_ERROR(test, [xfail|xpass])
# The baseline for 'test' must be in 'test.baseline'
# If arg #2 is not given, assume xpass
# The test will only be run if the --besdev option is set to 'yes'

m4_define([AT_CURL_RESPONSE_AND_HTTP_HEADER_TEST_ERROR], [dnl

    AT_SETUP([curl $1])
    AT_KEYWORDS([error])

    input=$abs_srcdir/$1
    baseline=$abs_srcdir/$1.baseline
    http_header=http_header$$

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([sed "s+@DAP_SERVICE@+$DAP_SERVICE+g" $input | curl -n -c cookies_file -b cookies_file -L -D $http_header -K -], [0], [stdout])
        REMOVE_DATE_HEADER([$http_header])
        AT_CHECK([mv stdout $baseline.tmp])
        dnl AT_CHECK([echo "^\c" > $baseline.http_header.tmp; head -1 $http_header | sed "s/\./\\\./g" >> $baseline.http_header.tmp])
        AT_CHECK([head -1 $http_header | tr -d '\r' > $input.http_header.tmp])
        ],
        [
        AT_SKIP_IF([test x$besdev = xno])
        AT_CHECK([sed "s+@DAP_SERVICE@+$DAP_SERVICE+g" $input | curl -n -c cookies_file -b cookies_file -L -D $http_header -K -], [0], [stdout])
        REMOVE_DATE_HEADER([$http_header])
        AT_CHECK([diff -b -B $baseline stdout], [0], [ignore])
        AT_CHECK([grep -f $input.http_header $http_header], [0], [ignore])
        AT_XFAIL_IF([test "$2" = "xfail" ])
        ])

    AT_CLEANUP
])
