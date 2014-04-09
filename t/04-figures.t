#!perl

# figures
# Various consitency checks for figures.

use Test::More;
use Data::Dumper;
no warnings 'uninitialized';

use Gcis::Client;
use v5.14;

my $c = Gcis::Client->new->use_env;
my $report = 'nca3';

my $chapters = $c->get("/report/$report/chapter?all=1");
ok @$chapters > 0, 'got '.@$chapters.' chapters';
if (my $only_chapter = $ENV{ONLY_CHAPTER}) {
    @$chapters = grep {$_->{number} eq $only_chapter} @$chapters;
}

for my $chapter (@$chapters) {
    my @figures = $c->figures(report => $report, chapter => $chapter->{identifier});
    my $chapter_short = $chapter->{number} // $chapter->{identifier};
    note "chapter $chapter_short figures : ".@figures;
    my %ordinals = map { $_ => 1 } 1..@figures;
    for my $figure (@figures) {
        my $href = $figure->{href};
        ok $href, "href for figure $figure->{identifier}";
        my $str = "^" . $c->url;
        like $href, qr[$str], "$href starts with ".$c->url;
        is $figure->{chapter_identifier}, $chapter->{identifier}, "chapter_identifier ok for $href";
        my $json = $c->ua->get($figure->{href})->success->json;
        is $json->{chapter}{identifier}, $chapter->{identifier}, "right chapter identifier for $href";
        ok defined($json->{ordinal}), "ordinal defined for $href";
        ok delete $ordinals{$json->{ordinal}}, "ordinal ".($json->{ordinal} // '<undef>')." is in the range 1 to ".@figures;
    }
    ok ( (keys %ordinals==0), "no missing figure ordinals in chapter $chapter_short" )
        or diag "missing figure ordinals in chapter $chapter_short : ".join ',', sort keys %ordinals;
}
 
done_testing();

