# Hyrax Regression Tests

Currently these tests depend on:
* A Hyrax server running on `localhost:8080` (but see the --server opetion)
* The programs `getdap` and `getdap4` must be on the PATH

## Build

```
autoreconf -vif
./configure 
make check
```

Once the tests have been built (use `make testsuite`), you can run them 
using `./testsuite`. and modify that using several options. See `./testsuite --help`.

Worth knowing:
1. The --jobs=N will speed up the tests quite a bit, especially with a remote 
server.
2. The --server=<host> option will switch from the default `localhost:8080` to
a different server. The server must have the stock data and handlers.
3. The --besdev=[yes|no] option toggles a set of error code tests that only work
with a server compiled using `--enable-developer` but are useful tests, all the same.
3. There are a number of keywords (-k <word>) that can be used to select groups of
related tests. For example, `./testsuite -j9 -k html` will run all of the tests that
get HTML responses. The keywords supported are html, test, error, dods, dap, and header.
