#!/usr/bin/perl

use strict;
use warnings;
use WWW::ipinfo;
use Switch;

use HTTP::Tiny;
use JSON;
use Data::Dumper;
use DateTime;
use Date::Parse;
use POSIX;
use Mastodon::Client;
use URI;


# api keys from api_keys file

my $key_file = 'api_keys';
my %api_keys;

open(my $fh, '<', $key_file) or die "Could not open file $key_file: $!";

while (<$fh>) {
  chomp;
  my ($key, $val) = split /=/;
  $api_keys{$key} = $val;
}

close $fh;

# getting IP address
my $ipinfo = get_ipinfo();
my @loc = split(",", $ipinfo->{loc});

for( ; ; ) {

printf ("New post\n");
    
# variables for openweathermap API
my $apikey = $api_keys{'OWMAPI'};

my $url = URI->new('http://api.openweathermap.org/data/2.5/weather');
$url->query_form(lat => $loc[0], lon => $loc[1], appid => $apikey);
my $wttr = "";
my $currentdata = from_json(HTTP::Tiny->new->get($url)->{content});
my @weather = $currentdata->{weather};

# reverse geoAPI
my $cityurl = URI->new('http://api.openweathermap.org/geo/1.0/reverse');
$cityurl->query_form(lat => $loc[0], lon => $loc[1], limit => '1', appid => $apikey);
my @city = from_json(HTTP::Tiny->new->get($cityurl)->{content});

# getting local name of the current city
my $cityname = $city[0][0]->{local_names}->{en};

# sunrise and sunset calculation
my $sunrise_text = "";
my $sunset_text = "";
my $sunrise = $currentdata->{sys}->{sunrise};
my $sunset = $currentdata->{sys}->{sunset};

$ENV{TZ} = 'Europe/Bratislava';
tzset;
my $currenttime = time();
my $dtnow = DateTime->now( time_zone => $ENV{TZ} );
my $clock = $dtnow->hms;
my $offset = $dtnow->offset;

if ($sunrise < $currenttime) {
    $sunrise_text = "has already risen up at ".DateTime->from_epoch($sunrise+$offset)->hms;
} else {
    $sunrise_text = "wil rise up at ".DateTime->from_epoch($sunrise+$offset)->hms;
}

if ($sunset < $currenttime) {
    $sunset_text = "has already set down at ".DateTime->from_epoch($sunset+$offset)->hms;
} else {
    $sunset_text = "will set down at ".DateTime->from_epoch($sunset+$offset)->hms;
}

# weather IDs to text
my $weatherid = $weather[0][0]->{id};
switch ($weatherid) {
    case [200..299] {$wttr = "are thunderstorms ☈"}
    case [300..399] {$wttr = "is a light rain ⛆"}
    case [500..599] {$wttr = "is raining ⛆"}
    case [600..699] {$wttr = "is snowing 🌨"}
    case [700..799] {$wttr = "is something else 🌫"}
    case 800 {$wttr = "is a clear sky ☉"}
    case 801 {$wttr = "are clouds here and there ☁"}
    case 802 {$wttr = "is more cloudy ☁☁"}
    case 803 {$wttr = "is even more cloudy ☁☁☁"}
    case 804 {$wttr = "is fully cloudy ☁☁☁☁"}
    else {$wttr = "it is unspecified"}
}
my $temperature = sprintf("%.2f", (($currentdata->{main}->{temp})-273));
# output
my $message = "Temperature in ".$cityname." is right now: ".$temperature." ℃ and outside ".$wttr.". Sun ".$sunrise_text." and ".$sunset_text.". Clock says it is ".$clock." where this bot lives.\n";

# mastodon part

my $client_id = $api_keys{'MASTO_CLIENT_ID'};
my $client_secret = $api_keys{'MASTO_CLIENT_SCRT'};
my $access_token = $api_keys{'MASTO_TOKEN'};


my $client = Mastodon::Client->new(
  instance        => 'tty0.social',
  name            => 'PerlBot',
  client_id       => $client_id,
  client_secret   => $client_secret,
  access_token    => $access_token,
  coerce_entities => 1,
);
 
$client->post_status($message);


printf("Waiting for 30 mins at ".$clock."\n");
sleep(1800);
}
