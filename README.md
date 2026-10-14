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

## What it takes to see "enabled"

The module reads `FIPS_mode()`, which on OpenSSL 3 is
`EVP_default_properties_is_fips_enabled(NULL)` -- so it answers yes when
the default properties of the library say `fips=yes`, and that needs the
FIPS provider to be present, installed and switched on:

1. A libcrypto with a FIPS provider.  FreeBSD's base OpenSSL has none:
   `/usr/lib/ossl-modules/` holds `legacy.so` and nothing else, and
   `openssl list -providers` shows only the default one.  `security/openssl`
   builds `fips.so` with its `FIPS` option, and says of it: *"NOT yet FIPS
   validated"*.
2. `openssl fipsinstall -out <prefix>/etc/ssl/fipsmodule.cnf -module
   <prefix>/lib/ossl-modules/fips.so`, which runs the self-tests and writes
   the module's MAC.  The provider does not load without that file.
3. `openssl.cnf`: `.include fipsmodule.cnf`, a `[provider_sect]` naming
   `fips` **and** `base` -- leave `base` out and everything that is not a
   FIPS algorithm disappears, PEM reading included -- and an `alg_section`
   with `default_properties = fips=yes`, which is the switch this module
   reads.
4. An nginx built against that libcrypto.  On FreeBSD that means
   `DEFAULT_VERSIONS+=ssl=openssl` rather than base.

Step 3 is a global change to the host's OpenSSL configuration, not an
nginx one: every program using that libcrypto is in FIPS mode afterwards.
And none of it makes the result *validated* -- it makes it FIPS mode.

## Building

```sh
ci/build.sh 1.30.5 /tmp/nginx-test            # into the binary
ci/build.sh 1.30.5 /tmp/nginx-test dynamic    # as a loadable object
```

The module needs libcrypto and takes it from nginx: a static build has to
be an nginx configured with SSL, a loadable one resolves the symbol
against the running binary.  An nginx without SSL has no FIPS mode to
report anyway.

On FreeBSD the ports tree builds this as `www/nginx-module-fips-check`,
and the three nginx server ports pick the sources up from there with their
`FIPS_CHECK` option.

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

Apache License 2.0.  The module is Owen Garrett's; the `NOTICE` file next
to [LICENSE](LICENSE) is his and travels with the work, as that licence
asks.  The scaffolding around it is under the same terms; see
[LICENSE](LICENSE).
