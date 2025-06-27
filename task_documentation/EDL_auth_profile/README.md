# Measure performance change due to EDL token self-validation 

After enabling Hyrax to self-validate EDL tokens, we need to measure the performance improvement. This directory contains the resources used for evaluation.

Ticket reference: HYRAX-1730

Steps to reproduce:
1. To capture the raw request timing data, we ran the series of steps below.
2. To plot the results of the tests, and generate summary statistics, run `julia --project=. analyze.jl`.

Test dependencies:
- `turl.sh` (included) available on path
- `edl_tokens_template` filled in with tokens available from `https://urs.earthdata.nasa.gov/users/<your_user_name>/user_tokens`, and saved to `~/.edl_tokens` 
- `jq` installed

To run more requests than the default 1000, update the loop in `request_fnoc.sh`.

## Capture request timing with and without EDL token self-validation

### Test on a local hyrax deployment

Script was run a machine in Boston, while NOT on a VPN or from an AWS instance; the data file accessed in this (and all preceding) tests lives on a server in the `us-west-2` region.

The following test was run on a local build of the olfs on the master branch (SHA # , i.e., after the changes to support self-validation had merged down), with hyrax client JWKS keys added in `/etc/olfs/user-access.xml`. For the "without self-validation" case, this JWKS was commented out so that the EDL authoraztion was used as a fallback. 

1. Ran hyrax locally, with local auth (as confirmed by turning on logs temporarily, seeing confirmation of JWKS being used, then restarting the server with logs disabled). Then ran
```bash
./request_fnoc.sh http://localhost:8080/opendap/ local_hr_keys
``` 

2. Commented out JWKS, restarted local hyrax server, then ran
```bash
./request_fnoc.sh http://localhost:8080/opendap/ local_hr_nokeys
```