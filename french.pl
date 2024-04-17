use strict;
use warnings;
use Env;
use DateTime::Calendar::FrenchRevolutionary;
use Data::Dumper;

$ENV{TZ} = "Europe/Bratislava";
my $dtrev = DateTime::Calendar::FrenchRevolutionary->from_object( object => DateTime->now( time_zone => $ENV{TZ}) );

printf("Aujourd'hui c'est: Année ".$dtrev->year.", Mois ".$dtrev->month_name." et Jour ".$dtrev->day_name." - ".$dtrev->abt_hms."\n");
