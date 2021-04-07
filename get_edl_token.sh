#!/bin/bash


#########################################################################################
#
# get_edl_authorization_header_from_hyrax()
#
# This little script makes a small DDS request to Hyrax, authenticating with EDL 
# (assuming .netrc is sorted) and then it utilizes the Hyrax user profile page 
# to retrive the EDL auth token value and type to build the Authorization header
# expected by the NGAP food chain.
#
function get_edl_authorization_header_from_hyrax() {
    hyrax_service_endpoint="${1}";
    
    cookies=$(mktemp /tmp/test_cookies.XXXXXX)
    burl="curl -s -L -c ${cookies} -b ${cookies} -n "
    
    fnoc1_dds=`${burl} ${hyrax_service_endpoint}/data/nc/fnoc1.nc.dds`
    token_type=`${burl} ${hyrax_service_endpoint}/login | grep token_type | awk '{print $3}' | sed -e "s/\"//g" -e "s/,//g"`
    access_token=`${burl} ${hyrax_service_endpoint}/login | grep access_token | awk '{print $3}' | sed -e "s/\"//g" -e "s/,//g"`
    edl_auth_header="Authorization: ${token_type} ${access_token}";
    
    echo ${edl_auth_header};
}

