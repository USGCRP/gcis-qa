use v5.14;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Gcis::QA',
    license             => 'gpl_3',
    dist_version        => '0.01',
    dist_author         => 'Brian Duggan <bduggan@usgcrp.gov>',
    dist_abstract       => "Client for Global Change Information System",
    release_status      => 'stable',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Gcis::Client' => '0.05',
    },
    add_to_cleanup     => [ 'Gcis-Client-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
