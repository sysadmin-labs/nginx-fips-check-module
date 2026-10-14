# nginx-fips-check-module

[![Build & Test][build-test-badge]][build-test-link]
[![FreeBSD][freebsd-badge]][freebsd-link]
[![A/UBSan][sanitizers-badge]][sanitizers-link]
[![Valgrind][valgrind-badge]][valgrind-link]
[![CodeQL][codeql-badge]][codeql-link]
[![Lint][lint-badge]][lint-link]

[build-test-badge]: https://github.com/sysadmin-labs/nginx-fips-check-module/actions/workflows/build-test.yml/badge.svg
[build-test-link]: https://github.com/sysadmin-labs/nginx-fips-check-module/actions/workflows/build-test.yml
[freebsd-badge]: https://github.com/sysadmin-labs/nginx-fips-check-module/actions/workflows/freebsd.yml/badge.svg
[freebsd-link]: https://github.com/sysadmin-labs/nginx-fips-check-module/actions/workflows/freebsd.yml
[sanitizers-badge]: https://github.com/sysadmin-labs/nginx-fips-check-module/actions/workflows/sanitizers.yml/badge.svg
[sanitizers-link]: https://github.com/sysadmin-labs/nginx-fips-check-module/actions/workflows/sanitizers.yml
[valgrind-badge]: https://github.com/sysadmin-labs/nginx-fips-check-module/actions/workflows/valgrind.yml/badge.svg
[valgrind-link]: https://github.com/sysadmin-labs/nginx-fips-check-module/actions/workflows/valgrind.yml
[codeql-badge]: https://github.com/sysadmin-labs/nginx-fips-check-module/actions/workflows/codeql.yml/badge.svg
[codeql-link]: https://github.com/sysadmin-labs/nginx-fips-check-module/actions/workflows/codeql.yml
[lint-badge]: https://github.com/sysadmin-labs/nginx-fips-check-module/actions/workflows/lint.yml/badge.svg
[lint-link]: https://github.com/sysadmin-labs/nginx-fips-check-module/actions/workflows/lint.yml

Report whether the OpenSSL that nginx is linked against is running in FIPS
mode, and refuse to carry on if that ever changes under a running server.

The module has no directives.  It runs once when a cycle starts and writes
one line:

```
2026/10/14 09:12:03 [notice] 7421#0: OpenSSL FIPS Mode is not enabled
```

That line is the point.  Whoever has to show that a server runs in FIPS
mode gets it from the process itself rather than from the configuration
that was supposed to arrange it, and a worker that comes up with a
different answer than the master found at startup aborts instead of
serving.

What it does not do: enable anything.  FIPS mode is a property of the
OpenSSL the server links against, set up outside nginx.

## Building

```sh
ci/build.sh 1.30.5 /tmp/nginx-test            # into the binary
ci/build.sh 1.30.5 /tmp/nginx-test dynamic    # as a loadable object
```

The module needs libcrypto and takes it from nginx: a static build has to
be an nginx configured with SSL, a loadable one resolves the symbol
against the running binary.  An nginx without SSL has no FIPS mode to
report anyway.

## Testing

```sh
ci/build.sh 1.30.5 /tmp/nginx-test
TEST_NGINX_BINARY=/tmp/nginx-test/sbin/nginx prove -r t/
```

The suite asks what a module without directives can be asked: that it
loads, that it reports the state it found, and that the report belongs to
the start of a cycle and not to a request.  It asserts the common prefix
of the two messages, so a host whose OpenSSL really is in FIPS mode passes
as well.

## License

Apache License 2.0, the module and the scaffolding around it alike; see
[LICENSE](LICENSE).  The module is Owen Garrett's, and so is the `NOTICE`
file beside it -- that licence asks for it to travel with the work, so it
does.
