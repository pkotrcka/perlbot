use strict;
use warnings;
use JSON;
use HTTP::Tiny;
use URI;
use DateTime;
use Data::Dumper;
use Mastodon::Client;


# api keys from api_keys file
my $oldflight = "";

my $key_file = 'api_keys';
my %api_keys;

open(my $fh, '<', $key_file) or die "Could not open file $key_file: $!";

while (<$fh>) {
  chomp;
  my ($key, $val) = split /=/;
  $api_keys{$key} = $val;
}

close $fh;

for ( ; ; ) {

my $flight = "";
my $airport = 'LKPR';
my $end = time()+7200;
my $begin = ($end - 28800);
print("B: ".$begin." E: ".$end."\n");
my $url = URI->new('https://opensky-network.org/api/flights/arrival?');
$url->query_form(airport => $airport, begin => $begin, end => $end);

my $response = HTTP::Tiny->new->get($url);
my $status = from_json($response->{status});
if ($status == 404) {
    $flight = "No flights in the last 8 hours.\n";
} else {
    $flight = (from_json($response->{content}))[0][0]->{callsign};
    print($flight."\n");
}
my $posturl = 'https://www.flightaware.com/live/flight/'.$flight;

# mastodon part

my $client_id = $api_keys{'MASTO_CLIENT_ID'};
my $client_secret = $api_keys{'MASTO_CLIENT_SCRT'};
my $access_token = $api_keys{'MASTO_TOKEN'};


my $message = "The last flight on the Airport ".$airport." was ".$flight." and you can find more details here: ".$posturl." \n";

my $client = Mastodon::Client->new(
  instance        => 'tty0.social',
  name            => 'PerlBot',
  client_id       => $client_id,
  client_secret   => $client_secret,
  access_token    => $access_token,
  coerce_entities => 1,
);
if ($flight eq $oldflight) {
    print("No new flights.\n");
} else {
    $oldflight = $flight;
    $client->post_status($message);
}

print("posted, waiting 10 minutes... \n");
sleep(600);
}
