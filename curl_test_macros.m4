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

AT_ARG_OPTION_ARG([server],
    [--server=host_name   Run tests against a server on this host (default localhost:8080)],
    [echo "server set to $at_arg_server"; SERVER=$at_arg_server],
    [echo "server default localhost:8080"; SERVER=localhost:8080])


# Usage: _AT_TEST_*(<bescmd source>, <baseline file>, <xpass/xfail> [default is xpass])

dnl Given a filename, remove any date-time string of the form "yyyy-mm-dd hh:mm:ss" 
dnl in that file and put "removed date-time" in its place. This hack keeps the baselines
dnl more or less true to form without the obvious issue of baselines being broken 
dnl one second after they are written.
dnl  
dnl Note that the macro depends on the baseline being a file.
dnl
dnl jhrg 6/3/16
dnl
dnl The regex was insufficient for time and hyrax version I have improved it.
dnl Here's the new regex with out the mad escaping.
dnl
dnl [0-9]{4}-[0-9]{2}-[0-9]{2}(\s|T)[0-9]{2}:[0-9]{2}:[0-9]{2}(\.\d+)?\s?(((\+|-)\d+)|(\D{1,5}))|(OPeNDAP Hyrax \([@0-9a-zA-Z.]+\))
dnl
dnl ndp 09/16/18
dnl
dnl sed does not support \d (and decimal digit) or \D (amd non-digit). I also removed the 'OPeNDAP
dnl Hyrax...' bit since we can use the PATH_HYRAX_RELEASE to remove the release information.
dnl
dnl NOTE: This is not currently used. jhrg 9/18/18
dnl
dnl m4_define([REMOVE_DATE_TIME], [dnl
dnl     sed 's@[[0-9]]\{4\}-[[0-9]]\{2\}-[[0-9]]\{2\}\(\s|T\)[[0-9]]\{2\}:[[0-9]]\{2\}:[[0-9]]\{2\}\(\.[[0-9]]+\)?\s?\(\(\(\+|-\)[[0-9]]+\)|\([[^0-9]]\{1,5\}\)\)@removed date-time@g' < $1 > $1.sed
dnl    dnl ' Added the preceding quote to quiet the Eclipse syntax checker. jhrg 3.2.18
dnl    mv $1.sed $1
dnl ])
dnl


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
    sed "s/$SERVER/@SERVER@/g" < $1 > $1.sed
    mv $1.sed $1
])

#######################################################################################
#
#   CURL TESTS

#--------------------------------------------------------------------------------------
#
# Basic test using diff  Response output should be text!!
#
# Usage: AT_CURL_RESPONSE_TEST(test, baseline, [xfail|xpass])
# If arg #3 is not given, assume xpass

m4_define([AT_CURL_RESPONSE_TEST], [dnl

    AT_SETUP([curl $1])
    AT_KEYWORDS([text])

    input=$abs_srcdir/$1
    baseline=$abs_srcdir/$1.baseline

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([sed "s/@SERVER@/$SERVER/g" $input | curl -K -], [0], [stdout])
        PATCH_HYRAX_RELEASE([stdout])
        PATCH_SERVER_NAME([stdout])

        AT_CHECK([mv stdout $baseline.tmp])
        ],
        [
        AT_CHECK([sed "s/@SERVER@/$SERVER/g" $input | curl -K -], [0], [stdout])
	    PATCH_HYRAX_RELEASE([stdout])
	    PATCH_SERVER_NAME([stdout])
        AT_CHECK([diff -b -B $baseline stdout], [0], [ignore])
        AT_XFAIL_IF([test "$3" = "xfail"])
        ])

    AT_CLEANUP
])

#--------------------------------------------------------------------------------------
#
# DAP2 Data response test
#
# Usage: AT_CURL_DAP2_DATA_RESPONSE_TEST(test, baseline, [xfail|xpass])
# If arg #3 is not given, assume xpass

m4_define([AT_CURL_DAP2_DATA_RESPONSE_TEST],  [dnl

    AT_SETUP([curl $1])
    AT_KEYWORDS([dods])

    input=$abs_srcdir/$1
    baseline=$abs_srcdir/$1.baseline

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([sed "s/@SERVER@/$SERVER/g" $input | curl -K - | getdap -Ms -], [0], [stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([mv stdout $baseline.tmp])
        ],
        [
        AT_CHECK([sed "s/@SERVER@/$SERVER/g" $input | curl -K - | getdap -Ms -], [0], [stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([diff -b -B $baseline stdout], [0], [ignore])
        AT_XFAIL_IF([test "$3" = "xfail"])
        ])

    AT_CLEANUP
])

#--------------------------------------------------------------------------------------
#
# DAP4 Data response test
#
# Usage: AT_CURL_DAP4_DATA_RESPONSE_TEST(test, baseline, [xfail|xpass])
# If arg #3 is not given, assume xpass

m4_define([AT_CURL_DAP4_DATA_RESPONSE_TEST],  [dnl

    AT_SETUP([CURL $1])
    AT_KEYWORDS([dap])

    input=$abs_srcdir/$1
    baseline=$abs_srcdir/$1.baseline

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([sed "s/@SERVER@/$SERVER/g" $input | curl -K - | getdap4 -D -M -s -], [0], [stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([mv stdout $baseline.tmp])
        ],
        [
        AT_CHECK([sed "s/@SERVER@/$SERVER/g" $input | curl -K - | getdap4  -D -M -s -], [0], [stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([diff -b -B $baseline stdout], [0], [ignore])
        AT_XFAIL_IF([test "$3" = "xfail"])
        ])

    AT_CLEANUP
])

#--------------------------------------------------------------------------------------
#
# ASCII Regex test
#
# Usage: AT_CURL_RESPONSE_PATTERN_MATCH_TEST(test, baseline, [xfail|xpass])
# If arg #3 is not given, assume xpass

m4_define([AT_CURL_RESPONSE_PATTERN_MATCH_TEST], [dnl

    AT_SETUP([curl $1])
    AT_KEYWORDS([pattern])

    input=$abs_srcdir/$1
    baseline=$abs_srcdir/$1.baseline

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([sed "s/@SERVER@/$SERVER/g" $input | curl -K -], [0], [stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([mv stdout $baseline.tmp])
        ],
        [
        AT_CHECK([sed "s/@SERVER@/$SERVER/g" $input | curl -K -], [0], [stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([grep -f $baseline stdout], [0], [ignore])
        AT_XFAIL_IF([test "$3" = "xfail"])
        ])

    AT_CLEANUP
])

#--------------------------------------------------------------------------------------
#
# ASCII Compare PLUS Check HTTP Header using REGEX
# The http_header baseline MUST be edited to make a correct regular expression
#
# Usage: AT_CURL_RESPONSE_AND_HTTP_HEADER_TEST(test, baseline, [xfail|xpass])
# If arg #3 is not given, assume xpass

m4_define([AT_CURL_RESPONSE_AND_HTTP_HEADER_TEST], [dnl

    AT_SETUP([curl $1])
    AT_KEYWORDS([header])

    input=$abs_srcdir/$1
    baseline=$abs_srcdir/$1.baseline

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([sed "s/@SERVER@/$SERVER/g" $input | curl -D http_header -K -], [0], [stdout])
        REMOVE_DATE_HEADER([http_header])
        AT_CHECK([mv stdout $baseline.tmp])
        AT_CHECK([echo "^\c" > $baseline.http_header.tmp; head -1 http_header | sed "s/\./\\\./g" >> $baseline.http_header.tmp])
        ],
        [
        AT_CHECK([sed "s/@SERVER@/$SERVER/g" $input | curl -D http_header -K -], [0], [stdout])
        REMOVE_DATE_HEADER([http_header])
        AT_CHECK([diff -b -B $baseline stdout], [0], [ignore])
        AT_CHECK([grep -f $baseline.http_header http_header], [0], [ignore])
        AT_XFAIL_IF([test "$3" = "xfail"])
        ])

    AT_CLEANUP
])


#--------------------------------------------------------------------------------------
# 
# Alternate version of the AT_CURL_HEADER_AND_RESPONSE_TEST for the forced-errors tests
# ASCII Compare PLUS Check HTTP Header using REGEX
# The http_header baseline MUST be edited to make a correct regular expression
#
# Usage: AT_CURL_RESPONSE_AND_HTTP_HEADER_TEST_ERROR(test, baseline, [xfail|xpass])
# If arg #3 is not given, assume xpass

m4_define([AT_CURL_RESPONSE_AND_HTTP_HEADER_TEST_ERROR], [dnl

    AT_SETUP([curl $1])
    AT_KEYWORDS([error])

    input=$abs_srcdir/$1
    baseline=$abs_srcdir/$1.baseline

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([sed "s/@SERVER@/$SERVER/g" $input | curl -D http_header -K -], [0], [stdout])
        REMOVE_DATE_HEADER([http_header])
        AT_CHECK([mv stdout $baseline.tmp])
        AT_CHECK([echo "^\c" > $baseline.http_header.tmp; head -1 http_header | sed "s/\./\\\./g" >> $baseline.http_header.tmp])
        ],
        [
        AT_CHECK([sed "s/@SERVER@/$SERVER/g" $input | curl -D http_header -K -], [0], [stdout])
        REMOVE_DATE_HEADER([http_header])
        AT_CHECK([diff -b -B $baseline stdout], [0], [ignore])
        AT_CHECK([grep -f $baseline.http_header http_header], [0], [ignore])
        AT_XFAIL_IF([test "$3" = "xfail" -o x$besdev = xno])
        ])

    AT_CLEANUP
])
