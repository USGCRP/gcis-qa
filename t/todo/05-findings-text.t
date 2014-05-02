#!perl

# findings
# compare the text to what is in the nca3review dump
BEGIN {
    binmode STDOUT, ':encoding(utf8)';
    binmode STDERR, ':encoding(utf8)';
}
use Test::More;
use Data::Dumper;
use Gcis::Client;
use Path::Class qw/file/;
use Mojo::DOM;
use Encode qw/encode decode/;
use v5.14;


my $c = Gcis::Client->new->use_env;
my $report = 'nca3';
my $review_dir = $ENV{REVIEW_DIR} || $ENV{HOME}.'/gcis/nca/nca3review';

-d $review_dir or do {
    plan skip_all => "Set REVIEW_DIR. ($review_dir) does not exist";
};

my $chapters = $c->get("/report/$report/chapter?all=1");
ok @$chapters > 0, 'got '.@$chapters.' chapters';
if (my $only_chapter = $ENV{ONLY_CHAPTER}) {
    @$chapters = grep {$_->{number} eq $only_chapter} @$chapters;
}

for my $chapter (@$chapters) {
    next unless $chapter->{number};
    note "doing chapter $chapter->{number}";
    my $file = sprintf("%s/html/ch%02d/ch%02d.html",$review_dir,$chapter->{number},$chapter->{number});
    -e $file or do {
        diag "cannot find $file";
        next;
    };
    my $contents = scalar file($file)->slurp;
    my $dom = Mojo::DOM->new($contents);
    my $chapter_text = $dom->all_text;
    my @nodes  = map { $_ } $dom->find('p')->each;
    my %statements;
    for my $i (0..$#nodes) {
        my $txt = $nodes[$i]->all_text;
        $txt =~ m[^key message #(\d+) traceable account]mi or next;
        my $ordinal = $1;
        my $statement = $nodes[$i+1]->all_text;
        $statement = decode('UTF-8',$statement);
        chop $statement if ord(substr($statement,-1,1)) == 65533;
        $statements{$ordinal} = _munge($statement);
    }

    for my $finding ($c->findings(report => $report, chapter => $chapter->{identifier})) {
        is $finding->{statement}, $statements{$finding->{ordinal}}, "gcis matches word doc for $finding->{href}";
    }

}
TODO: {
    local $TODO = "report findings";
}

sub _munge {
    my $str = shift;
    $str =~ s/R ising/Rising/;
    return $str;
}

done_testing();

