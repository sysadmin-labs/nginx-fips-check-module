# Changelog

Newest first.  Dates are release dates.

## v0.2 (2026-10-14)

### Fixed

- **The static branch of `config` named a file that does not exist.**  The
  loadable branch compiles `ngx_core_fips_check_module.c`, the static one
  asked for `ngx_fips_check_module.c`, so an nginx configured with
  `--add-module` instead of `--add-dynamic-module` failed to build.  The
  loadable branch is the one everybody uses, which is why it survived.

### Changed

- The source moved into `src/`, where every other module in this
  organization keeps it, and both branches of `config` name it from there.

### Added

- `t/`, which asks the two things that can be asked of a module with no
  directives and no request handling: that it loads and reports the state
  it found, and that the report belongs to the start of a cycle rather
  than to a request.  The assertion is the common prefix of the two
  messages, so a run on a host whose OpenSSL really is in FIPS mode passes
  as well.

- The scaffolding the other modules in this organization carry: a version
  and digest pin for every build input, the release matrix with both a
  static and a loadable build, the FreeBSD virtual machine, A/UBSan,
  valgrind, CodeQL, shellcheck and actionlint.

### Removed

- **No reload gate, and that is deliberate.**  The other modules in this
  organization are reloaded eight times in a row and asked afterwards
  whether they still answer, because a module that allocates something per
  cycle and never gives it back is invisible otherwise.  This one
  allocates nothing: no configuration structures, no pools, no shared
  memory, no connections.  It was tried, and the measurement says the same
  thing from the other side -- the module keeps what it found in a static
  and writes a line only while that is still unknown, so after eight
  reloads the log holds exactly the two lines the first start wrote.  A
  gate whose probe cannot change is a badge, not a check.

- The upstream `README.md`'s build instructions, which were about
  assembling a loadable module by hand against an NGINX Plus release.
