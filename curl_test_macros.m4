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

AT_ARG_OPTION_ARG([hyraxurl],
    [--hyraxurl=hyrax-service-endpoint-url Run the various tests (DAP2/4, w10n,
    wcs, etc.) against the Hyrax instance located at the specified endpoint URL.
    (default: http://localhost:8080/opendap)],
    [echo "Hyrax service url set to: $at_arg_hyraxurl"; HYRAX_ENDPOINT_URL=$at_arg_hyraxurl],
    [echo "Hyrax service url using default: http://localhost:8080/opendap"; HYRAX_ENDPOINT_URL=http://localhost:8080/opendap])

AT_ARG_OPTION_ARG([builddmrpp_url],
    [--builddmrpp_url=builddmrpp-service-endpoint-url Run the various tests (DAP2/4, w10n,
    wcs, etc.) against the Hyrax instance located at the specified endpoint URL.
    (default: http://localhost:8080/build_dmrpp)],
    [echo "BuildDmrpp service url set to: $at_arg_builddmrpp_url"; BUILDDMRPP_ENDPOINT_URL=$at_arg_builddmrpp_url],
    [echo "BuildDmrpp service url using default: http://localhost:8080/build_dmrpp"; BUILDDMRPP_ENDPOINT_URL=http://localhost:8080/build_dmrpp])

AT_ARG_OPTION_ARG([netrc],
    [--netrc=netrc_file_name Run tests using the specified netrc file (ala cURL). (default: ~/.netrc)],
    [echo "netrc file set to: $at_arg_netrc"; CURL_NETRC_FILE=$at_arg_netrc],
    [echo "netrc file using default: ~/.netrc"; CURL_NETRC_FILE=~/.netrc])

AT_ARG_OPTION_ARG([enableinsecure],
    [--enableinsecure=yes|no   Check or don't check TLS certificate validity. ],
    [echo "ENABLE_INSECURE set to $at_arg_enableinsecure"; ENABLE_INSECURE=-k],
    [ENABLE_INSECURE=])
    
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
    HTTPS_URL=`echo $HYRAX_ENDPOINT_URL | sed -e "s+http://+https://+g" | tee https_url` &&
    dnl echo "HTTPS_ENDPOINT_URL: ${HTTPS_URL}" &&
    HTTP_URL=`echo $HYRAX_ENDPOINT_URL | sed -e "s+https://+http://+g" | tee http_url` &&
    dnl echo "HTTP_ENDPOINT_URL: ${HTTP_URL}" &&
    sed -e "s+$HTTP_URL+@HYRAX_ENDPOINT_URL@+g" -e "s+$HTTPS_URL+@HYRAX_ENDPOINT_URL@+g"  < $1 > $1.sed
    mv $1.sed $1
])

dnl Given a filename, remove any version string of the form <Value>3.20.9</Value>
dnl or <Value>libdap-3.20.8</Value> in that file and put "removed version" in its
dnl place. This hack keeps the baselines more or less true to form without the
dnl obvious issue of baselines being broken when versions of the software are changed.
dnl
dnl Added support for 'dmrpp:version="3.20.9"' in the root node of the dmrpp.
dnl
dnl Note that the macro depends on the baseline being a file.
dnl
dnl jhrg 12/29/21

m4_define([REMOVE_VERSIONS], [dnl
    sed -r -e 's@<Value>[[0-9]]*\.[[0-9]]*\.[[0-9]]*</Value>@<Value>removed-version</Value>@g' \
    -e 's@<Value>[[A-z_.]]*-[[0-9]]*\.[[0-9]]*\.[[0-9]]*</Value>@<Value>removed-version</Value>@g' \
    -e 's@dmrpp:version="[[0-9]]*\.[[0-9]]*\.[[0-9]]*"@removed-dmrpp:version@g' \
    -e 's@[[0-9]]+\.[[0-9]]+\.[[0-9]]+(-[[0-9]]+)?@removed-version@g' \
    < $1 > $1.sed
    mv $1.sed $1
])

dnl Remove BES.Catalog.catalog.RootDirectory and BES.module.* from the baseline or returned
dnl DMR++ response. jhrg 6/12/23
dnl
dnl Note: Using '$@' in a macro definition confuses M $@ is replaced with a list of all arguments
dnl where each argument is quoted ($* does not quote the arguments). So, I switched to using '|'
dnl as the delimiter for the sed expressions in the macro below. jhrg 6/12/23
dnl
m4_define([REMOVE_BES_CONF_LINES], [dnl
    sed -e 's|^BES\.Catalog\.catalog\.RootDirectory=.*$|removed line|g' \
        -e 's|^BES\.module\..*=.*$|removed line|g' < $1 > $1.sed
    mv $1.sed $1
])

dnl Remove BuildDmrpp configuration from the baseline or returned DMR++ response. ndp 11/06/23
dnl
m4_define([REMOVE_BUILD_DMRPP_CONFIGURATION_ATTR], [dnl
    # This sed magic: '1h;2,$H;$!d;g' slurps up the entire file into a single line.
    # Courtesy of: https://unix.stackexchange.com/users/21763/antak
    #   Reference: https://unix.stackexchange.com/questions/26284/how-can-i-use-sed-to-replace-a-multi-line-string
    sed \
        -e '1h;2,$H;$!d;g' \
        -e 's@<Attribute name="configuration" type="String">.*</Value>@<Attribute name="Removed(configuration)">@' \
         < $1 > $1.sed
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
        AT_CHECK([
            sed -e "s+@HYRAX_ENDPOINT_URL@+$HYRAX_ENDPOINT_URL+g" $input |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c $abs_builddir/cookies_file -b $abs_builddir/cookies_file -L -K -],
            [0], [stdout])
        PATCH_HYRAX_RELEASE([stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([mv stdout $baseline.tmp])
        ],
        [
        AT_CHECK([
            sed -e "s+@HYRAX_ENDPOINT_URL@+$HYRAX_ENDPOINT_URL+g" $input |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c $abs_builddir/cookies_file -b $abs_builddir/cookies_file -L -K -],
            [0], [stdout])
	    PATCH_HYRAX_RELEASE([stdout])
	    PATCH_SERVER_NAME([stdout])
        AT_CHECK([diff -b -B $baseline stdout], [0], [ignore])
        AT_XFAIL_IF([test "$2" = "xfail"])
        ])

    AT_CLEANUP
])


# Usage: AT_CURL_BUILDDMRPP_RESPONSE_TEST(test, [xfail|xpass])
# The baseline for 'test' must be in 'test.baseline'
# If arg #2 is not given, assume xpass

m4_define([AT_CURL_BUILDDMRPP_RESPONSE_TEST], [dnl

    AT_SETUP([curl $1])
    AT_KEYWORDS([text])

    input="$abs_srcdir/$1"
    baseline="$abs_srcdir/$1.baseline"
    curl_cmd=$(sed -e "s+@BUILDDMRPP_ENDPOINT_URL@+$BUILDDMRPP_ENDPOINT_URL+g" $input)
    cookies_file="$abs_builddir/cookies_file"

    AS_IF([test -z "$at_verbose"], [
        echo ""
        echo "# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
        echo "# AT_CURL_BUILDDMRPP_RESPONSE_TEST: BEGIN"
        echo "#           input: $input"
        echo "#        baseline: $baseline"
        echo "# CURL_NETRC_FILE: $CURL_NETRC_FILE"
        echo "#    cookies_file: $cookies_file"
        echo "#        curl_cmd: (filtered file contents follow)"
        echo "$curl_cmd"
        echo "#"
    ])

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([
            echo "$curl_cmd" |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c "$cookies_file" -b "$cookies_file" -L -K -],
            [0], [stdout])
        REMOVE_VERSIONS([stdout])
        REMOVE_BES_CONF_LINES([stdout])
        REMOVE_BUILD_DMRPP_CONFIGURATION_ATTR([stdout])
        AT_CHECK([mv stdout $baseline.tmp])
        ],
        [
        AT_CHECK([
            echo "$curl_cmd" |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c "$cookies_file" -b "$cookies_file" -L -K -],
            [0], [stdout])
	    REMOVE_VERSIONS([stdout])
	    REMOVE_BES_CONF_LINES([stdout])
	    REMOVE_BUILD_DMRPP_CONFIGURATION_ATTR([stdout])
        AT_CHECK([diff -b -B $baseline stdout], [0], [ignore])
        AT_XFAIL_IF([test "$2" = "xfail"])
        ])

    AS_IF([test -z "$at_verbose"], [
        echo "# AT_CURL_BUILDDMRPP_RESPONSE_TEST: END"
        echo "# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
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
        AT_CHECK([
            sed -e "s+@HYRAX_ENDPOINT_URL@+$HYRAX_ENDPOINT_URL+g" $input |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c $abs_builddir/cookies_file -b $abs_builddir/cookies_file -L -K - | 
            getdap -Ms -], [0], [stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([mv stdout $baseline.tmp])
        ],
        [
        AT_CHECK([
            sed -e "s+@HYRAX_ENDPOINT_URL@+$HYRAX_ENDPOINT_URL+g" $input |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c $abs_builddir/cookies_file -b $abs_builddir/cookies_file -L -K - | 
            getdap -Ms -], [0], [stdout])
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
        AT_CHECK([
            sed -e "s+@HYRAX_ENDPOINT_URL@+$HYRAX_ENDPOINT_URL+g" $input |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c $abs_builddir/cookies_file -b $abs_builddir/cookies_file -L -K - | 
            getdap4 -D -M -s -], [0], [stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([mv stdout $baseline.tmp])
        ],
        [
        AT_CHECK([
            sed -e "s+@HYRAX_ENDPOINT_URL@+$HYRAX_ENDPOINT_URL+g" $input |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c $abs_builddir/cookies_file -b $abs_builddir/cookies_file -L -K - | 
            getdap4 -D -M -s -], [0], [stdout])
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
        AT_CHECK([
            sed -e "s+@HYRAX_ENDPOINT_URL@+$HYRAX_ENDPOINT_URL+g" $input |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c $abs_builddir/cookies_file -b $abs_builddir/cookies_file -L -K -], [0], [stdout])
        PATCH_SERVER_NAME([stdout])
        AT_CHECK([mv stdout $baseline.tmp])
        ],
        [
        AT_CHECK([
            sed -e "s+@HYRAX_ENDPOINT_URL@+$HYRAX_ENDPOINT_URL+g" $input |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c $abs_builddir/cookies_file -b $abs_builddir/cookies_file -L -K -], [0], [stdout])
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
    dnl same file name. I''m not sure autotest is smart enough to recognize that situation
    dnl for an arbitrary file. It does seem to delete the file.
    http_header=http_header$$

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([
            sed -e "s+@HYRAX_ENDPOINT_URL@+$HYRAX_ENDPOINT_URL+g" $input |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c $abs_builddir/cookies_file -b $abs_builddir/cookies_file -L -D $http_header -K -], [0], [stdout])
        dnl REMOVE_DATE_HEADER([$http_header])
        AT_CHECK([mv stdout $baseline.tmp])
        AT_CHECK([head -1 $http_header | tr -d '\r' > $input.http_header.tmp])
        ],
        [
        AT_CHECK([
            sed -e "s+@HYRAX_ENDPOINT_URL@+$HYRAX_ENDPOINT_URL+g" $input |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c $abs_builddir/cookies_file -b $abs_builddir/cookies_file -L -D $http_header -K -], [0], [stdout])
        dnl REMOVE_DATE_HEADER([$http_header])
        AT_CHECK([diff -b -B $baseline stdout], [0], [ignore])
        AT_CHECK([grep -E -f $input.http_header $http_header], [0], [ignore])
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
    dnl same file name. I''m not sure autotest is smart enough to recognize that situation
    dnl for an arbitrary file. It does seem to delete the file.
    http_header=http_header$$

    AS_IF([test -n "$baselines" -a x$baselines = xyes],
        [
        AT_CHECK([
            sed -e "s+@HYRAX_ENDPOINT_URL@+$HYRAX_ENDPOINT_URL+g" $input |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c $abs_builddir/cookies_file -b $abs_builddir/cookies_file -L -D $http_header -K - > /dev/null], [0], [ignore])

        dnl The first line of the headers is the HTTP return status.
        dnl Remove the CR from the CRLF pair so that grep can use the line for a string/pattern match.
        dnl NB: sed on OSX does not recognize \r, so use tr to remove the CR character. jhrg 2/20/20
        AT_CHECK([head -1 $http_header | tr -d '\r' > $input.http_header.tmp])
        ],
        [
        AT_CHECK([
            sed -e "s+@HYRAX_ENDPOINT_URL@+$HYRAX_ENDPOINT_URL+g" $input |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c $abs_builddir/cookies_file -b $abs_builddir/cookies_file -L -D $http_header -K -], [0], [stdout])

        dnl -F: test strings, not patterns. This test just looks for the HTTP response code.
        AT_CHECK([grep -E -f $input.http_header $http_header], [0], [ignore])

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
        AT_CHECK([
            sed -e "s+@HYRAX_ENDPOINT_URL@+$HYRAX_ENDPOINT_URL+g" $input |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c $abs_builddir/cookies_file -b $abs_builddir/cookies_file -L -D $http_header -K -], [0], [stdout])
        REMOVE_DATE_HEADER([$http_header])
        AT_CHECK([mv stdout $baseline.tmp])
        AT_CHECK([head -1 $http_header | tr -d '\r' > $input.http_header.tmp])
        ],
        [
        AT_SKIP_IF([test x$besdev = xno])
        AT_CHECK([
            sed -e "s+@HYRAX_ENDPOINT_URL@+$HYRAX_ENDPOINT_URL+g" $input |
            curl $ENABLE_INSECURE --netrc-file $CURL_NETRC_FILE --netrc-optional -c $abs_builddir/cookies_file -b $abs_builddir/cookies_file -L -D $http_header -K -], [0], [stdout])
        REMOVE_DATE_HEADER([$http_header])
        AT_CHECK([diff -b -B $baseline stdout], [0], [ignore])
        AT_CHECK([grep -E -f $input.http_header $http_header], [0], [ignore])
        AT_XFAIL_IF([test "$2" = "xfail" ])
        ])

    AT_CLEANUP
])
