#!perl

use Test::More;

use_ok "Gcis::Client 0.02";
note "client version $Gcis::Client::VERSION";

my $c = Gcis::Client->new->use_env;
ok $c, "made client object";

my $nca3 = $c->get('/report/nca3');

like $nca3->{title}, qr/Third National Climate Assessment/, "NCA3 report title";

done_testing();

