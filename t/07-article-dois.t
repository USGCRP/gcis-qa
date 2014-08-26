#!perl

BEGIN {
    binmode STDOUT, ':encoding(utf8)';
    binmode STDERR, ':encoding(utf8)';
}

use Test::More;
use Gcis::Client;
use strict;

my $c = Gcis::Client->new->use_env;
my $d = Gcis::Client->new->accept("application/vnd.citationstyles.csl+json;q=0.5")
                          ->url("http://dx.doi.org");

my $articles = $c->get('/article');

ok scalar @$articles, "got some articles";
note "count : ".@$articles;

for my $article (@$articles) {
    my $doi = $article->{doi};
    my $uri = $article->{uri};
    my $href = $article->{href};
    $href =~ s/.json$//;
    ok $doi, "got a doi";
    my $crossref = $d->get("/$doi");
    ok keys %$crossref, "Valid doi : http://dx.doi.org/$doi";
    SKIP: {
        skip "Missing crossref data for $doi", 1 unless keys %$crossref;
        is $crossref->{title}, $article->{title}, "title for $href" or diag "got http://dx.doi.org/$doi for $href";
        is $article->{year},           $crossref->{deposited}{'date-parts'}[0][0], "year for $href";
        is $article->{journal_vol},    $crossref->{volume}, "volume for $href";
        #is $article->{journal}{title}, $crossref->{'container-title'}, "journal title";
    }
}

done_testing();

