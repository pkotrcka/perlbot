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
my $sunrise = $currentdata->{sys}->{sunrise};
my $sunset = $currentdata->{sys}->{sunset};

# weather IDs to text
my $weatherid = $weather[0][0]->{id};
switch ($weatherid) {
    case [200..299] {$wttr = "Thunderstorms ☈"}
    case [300..399] {$wttr = "Light rain ⛆"}
    case [500..599] {$wttr = "Raining ⛆"}
    case [600..699] {$wttr = "Snowing 🌨"}
    case [700..799] {$wttr = "Something else 🌫"}
    case 800 {$wttr = "Clear sky"}
    case 801 {$wttr = "Few clouds ☁"}
    case 802 {$wttr = "More cloudy ☁☁"}
    case 803 {$wttr = "Even more cloudy ☁☁☁"}
    case 804 {$wttr = "Fully cloudy ☁☁☁☁"}
    else {$wttr = "Unspecified"}
}
my $temperature = sprintf("%.2f", (($currentdata->{main}->{temp})-273));

my $post_text=("Weather in: ".$cityname."\nTemperature: ".$temperature." ℃\nWeather: ".$wttr);

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
 
$client->post_status($post_text);

sleep(1800);
}
