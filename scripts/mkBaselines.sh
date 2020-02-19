#!/bin/bash
#set -x;
#set -e;
# Saṃsāra

TEST_RESULTS_FILE=$(mktemp -t mkBaselines_XXXX)
echo "Test results will be stored in: ${TEST_RESULTS_FILE}"

FAILED_TESTS=`./hyraxTest -v | tee ${TEST_RESULTS_FILE} | grep FAILED`

if [ ! -n "${FAILED_TESTS}" ] 
then
    echo "No Tests Failed. w00t!"
    exit 0
fi

echo "Failed Tests: "; echo "${FAILED_TESTS}";
echo "Processing Failed tests..."
while read failed_test
do
    echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - "
    echo "Updating baseline for test ${failed_test}"
        
    test_code_location=`echo ${failed_test} | awk '{print $2;}' -`
    echo "test_code_location: ${test_code_location}"
    
    test_info=`grep "${test_code_location} testing CURL" ${TEST_RESULTS_FILE}`
    echo "test_info: ${test_info}"
    
    test_id=`echo  "${test_info}" | awk '{printf("%03d",$1); }' -`;
    echo "test_id: ${test_id}";

    test_file=`echo "${test_info}" | awk '{print substr($5,13);}' -`;
    echo "test_file: ${test_file}";
    
    baseline_file="${test_file}.baseline";
    echo "baseline_file: ${baseline_file}";
    
    test_result_file="./hyraxTest.dir/${test_id}/stdout";
    echo "test_result_file: ${test_result_file}";

    cp "${test_result_file}" "${baseline_file}";

done < <( echo "${FAILED_TESTS}"; );

exit 





