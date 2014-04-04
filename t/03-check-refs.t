#!perl

# check-refs
# Find discrepancies between tbib tags in text and references associated with a resource.

use Test::More;
use Data::Dumper;
no warnings 'uninitialized';

use Gcis::Client;
use v5.14;

my $c = Gcis::Client->new->use_env;
my $report = 'nca3';

sub check_refs {
    my $what = shift;
    my $chapter_identifier = shift;
    my @objs = $c->$what(report => $report, chapter => $chapter_identifier);

    for my $f (@objs) {
        my $uri = $f->{uri} or die "missing uri";
        # diag "checking $uri";
        my $resource = $c->get($uri);
        my %endnote_to_uuid;

        my @uuids;
        for my $key (keys %$resource) {
            my $val = $resource->{$key};
            next if ref $val;
            #diag "value of $key is $val" if $key =~ /source/;
            while ($val =~ m[<tbib>([a-z0-9-]{36})</tbib>]g) {
                push @uuids, $1;
            }
            #diag  "after $key we have @uuids";
        }
        #diag "found @uuids"; 

        my $refs = $resource->{references};
        my @have;
        for (@$refs) {
            $_->{uri} =~ m[/reference/(.*)$] or die "weird ref uri $_->{uri}";
            push @have, $1;
        }
        my %in_text;
        my %in_refs;
        $in_text{$_} = 1 for @uuids;
        $in_refs{$_} = 1 for @have;
        is scalar keys %in_text, scalar keys %in_refs, "uuids matched for $f->{href}";
        is_deeply \%in_text, \%in_refs, sprintf("%d uuid%s in text matches refs for $resource->{href}",
                scalar keys %in_text,
                keys %in_text==1 ? '' : 's');
    }
}

my $chapters = $c->get("/report/$report/chapter?all=1");
ok @$chapters > 0, 'got '.@$chapters.' chapters';

for my $what (qw/figures findings tables/) {
    for my $chapter (@$chapters) {
        note "Checking $what for chapter ".($chapter->{number} || $chapter->{identifier});
        check_refs($what, $chapter->{identifier});
    }
}

done_testing();

