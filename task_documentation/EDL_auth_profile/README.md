# Measure performance change due to EDL token self-validation 

After enabling Hyrax to self-validate EDL tokens, we need to measure the performance improvement. This directory contains the resources used for evaluation.

Ticket reference: HYRAX-1730

Steps to reproduce:
1. To capture the raw request timing data, we ran the series of steps below.
2. To plot the results of the tests, and generate summary statistics, run `julia --project=. analyze.jl`.

Analysis script is brittle; will likely require refactoring for any sort of scripted usage.

Test dependencies:
- `turl.sh` available on path
- `~/.edl_tokens`
- `jq` installed

## Capture request timing with and without EDL token self-validation

### 1. Test on a local hyrax deployment

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

## 2. Test on `<TEST_SERVER>`

Script was run a machine in Boston, while connected to an east coast VPN; the hyrax server being accessed, data file being accessed, and EDL validation endpoint (when used) are all in the `us-west-2` region.

For `<TEST_SERVER>`, replaced with name of appropriate test/staging/prod server. 

1. Deployed a branch of Hyrax with the correct JWKS injected at deploy time. Then ran:
```bash
./run.sh https://opendap.<TEST_SERVER>.earthdata.nasa.gov <TEST_SERVER>_hr_keys
```

2. Deployed a branch of Hyrax with the JKWS field name mangled, such that no JWKS keys were injected at deploy time. Then ran:
```bash
./run.sh https://opendap.<TEST_SERVER>.earthdata.nasa.gov <TEST_SERVER>_hr_no_keys
```

When running the analysis script, be sure to pass in the name of the `TEST_SERVER`: 
```
julia --project=. analyze TEST_SERVER
```

## Local sanity check, before running via script

Make sure each works before moving on to the next:
1. Basic access without creds fails:
```bash
curl https://opendap.earthdata.nasa.gov/hyrax/data/nc/fnoc1.nc.dds -L
```
...should get an HTTP access denied.

2. Access with creds succeeds:
```bash
turl https://opendap.earthdata.nasa.gov/hyrax/data/nc/fnoc1.nc.dds
```
...if your ~/.edl_tokens are set correctly, should get back the same values as you see in the browser after signing in: https://opendap.earthdata.nasa.gov/hyrax/data/nc/fnoc1.nc.dds 

3. Access via the script succeeds:
```bash
./run.sh https://opendap.earthdata.nasa.gov _delete1
```
If this fails, make sure your url doesn't end in a slash. If this succeeds, you're good to go on to the server test.

4. Also try your environment, make sure it succeeds, via turl and then via the script:
```bash
turl https://opendap.<SERVER_ENV>.earthdata.nasa.gov/hyrax/data/nc/fnoc1.nc.dds
```