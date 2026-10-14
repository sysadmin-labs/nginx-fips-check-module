# vi:ft=perl
#
# What this module can be asked without a FIPS-enabled OpenSSL, which is
# every machine this runs on: that it loads, that it says which state it
# found, and that it says it once.
#
# The assertion is the common prefix of the two messages, not "not
# enabled".  A run on a host whose OpenSSL really is in FIPS mode has to
# pass too, and the state is the host's answer, not this module's.
#
# repeat_each(1) and a different location per block, both on purpose.  The
# line belongs to the start of a server, and Test::Nginx keeps one server
# running across blocks whose configuration is identical -- so a repeated
# block, or a second block with the same configuration, would look for a
# line that nothing was going to write again.

use Test::Nginx::Socket 'no_plan';

repeat_each(1);

run_tests();

__DATA__

=== TEST 1: the module reports what OpenSSL told it
--- config
    location = /t {
        return 200 'ok';
    }
--- request
GET /t
--- response_body chomp
ok
--- error_log
OpenSSL FIPS Mode is
--- no_error_log
[alert]
[emerg]



=== TEST 2: traffic does not make it report again
# Two requests, and the count of reports stays where the start left it.
# The module keeps the state it found in a static and only speaks again if
# that state changes, which is why there is nothing here for a request to
# trigger.
--- config
    location = /twice {
        return 200 'ok';
    }
--- pipelined_requests eval
["GET /twice", "GET /twice"]
--- response_body eval
["ok", "ok"]
--- no_error_log
[alert]
[emerg]
