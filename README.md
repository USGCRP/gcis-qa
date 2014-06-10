Global Change Information System QA [![Build Status](https://secure.travis-ci.org/USGCRP/gcis-qa.png)](http://travis-ci.org/USGCRP/gcis-qa)
====================================

Quick start :

    ./run-tests http://data.globalchange.gov

To run an individual test :

    export GCIS_API_URL=http://data.globalchange.gov
    prove t/02-client.t

Or :
   perl Build.PL
   GCIS_API_URL=http://data.globalchange.gov ./Build test

Contents :

    ./run-tests  -- script to run the tests
    t/           -- directory containing tests

Have fun!

