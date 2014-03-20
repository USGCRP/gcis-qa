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
    my @objs = $c->$what(report => $report, chapter_number => $chapter_identifier);

    for my $f (@objs) {
        my $uri = $f->{uri} or die "missing uri";
        my $resource = $c->get($uri);
        my %endnote_to_uuid;

        my @uuids;
        for (values %$resource) {
            next if ref $_;
            push @uuids, ($_ =~ m[<tbib>([a-z0-9-]+)</tbib>]g);
        }

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
        is_deeply \%in_text, \%in_refs, sprintf("%d uuid%s for $resource->{uri}",scalar keys %in_text,
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

