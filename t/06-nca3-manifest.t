#!/usr/bin/env perl

use Gcis::Client;
use v5.14;
use Test::More;
use Path::Class qw/file/;
use FindBin;
use Mojo::Util qw/sha1_sum/;
no warnings 'uninitialized';

BEGIN {
    $ENV{MOJO_MAX_MESSAGE_SIZE} = 1024 * 1024 * 1024 * 1024;
}

my $manifest = "$FindBin::Bin/../etc/MANIFEST.nca3";
my $c = Gcis::Client->new->use_env;

ok -e $manifest, "found manifest file";
my %sha2file = map { m/^(\S+) +(.*)$/; } file($manifest)->slurp;

my $report = $c->get('/report/nca3')->{files};
ok @$report==2, "2 files for report";
for (@$report) {
    my $found = delete $sha2file{$_->{sha1}};
    ok $found, "found sha1 for report in manifest";
}

my $chapters = $c->get("/report/nca3/chapter?all=1");
for (@$chapters) {
    my $chapter = $c->get($_->{uri});
    my $files = $chapter->{files};
    ok $files && @$files==2, "Two files for $chapter->{href}";
    for my $f (@$files) {
        like $f->{location}, qr/nca2014\.globalchange\.gov/, "file is on the right host";
        my $found = delete $sha2file{$f->{sha1}};
        ok $found, "found file $f->{sha1} for $chapter->{identifier} ($found)";
        my $url = $f->{url};
        #diag "getting $url";
        my $tx = $c->ua->get($url);
        my $res = $tx->success;
        ok $res, "able to retrieve $f->{url}";
        unless ($res) {
            diag "error for $f->{uri} : ".$tx->error;
            next;
        }
        my $sha1 = sha1_sum($res->body);
        is $sha1, $f->{sha1}, "sha1 match for ".$f->{file};

    }
}

ok (values %sha2file)==5, "five left over";

done_testing();

