#!/usr/bin/perl

# Tests for ngx_stream_label_module.

###############################################################################

use warnings;
use strict;

use Test::More;

BEGIN { use FindBin; chdir($FindBin::Bin); }

use lib 'lib';
use Test::Nginx;
use Test::Nginx::Stream qw/ stream /;

###############################################################################

select STDERR; $| = 1;
select STDOUT; $| = 1;

my $t = Test::Nginx->new()
	->has(qw/stream stream_return ngx_stream_label_module/)
	->plan(4);

$t->write_file_expand('nginx.conf', <<'EOF');

%%TEST_GLOBALS%%

daemon off;

events {
}

stream {
    %%TEST_GLOBALS_STREAM%%

    label Environment production;
    label cluster_id edge-01;
    labels_hash_max_size 128;
    labels_hash_bucket_size 64;

    server {
        listen  127.0.0.1:8080;
        return  "$label_environment";
    }

    server {
        listen  127.0.0.1:8081;
        return  "$label_Environment";
    }

    server {
        listen  127.0.0.1:8082;
        return  "$labels";
    }

    server {
        listen  127.0.0.1:8083;
        return  "<$label_unknown>";
    }
}

EOF

$t->run();

###############################################################################

is(stream('127.0.0.1:' . port(8080))->read(), 'production',
	'label variable');
is(stream('127.0.0.1:' . port(8081))->read(), 'production',
	'label variable name is case insensitive');
is(stream('127.0.0.1:' . port(8082))->read(),
	'environment=production&cluster_id=edge-01', 'all labels');
is(stream('127.0.0.1:' . port(8083))->read(), '<>', 'unknown label');

###############################################################################
