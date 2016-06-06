#!/usr/bin/env perl

#   Copyright 2016 Aino.io
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.


use strict;
use warnings;

use Getopt::Long qw(GetOptions);
require 'AinoLib.pm';

use Data::Dumper qw(Dumper);

my $api_address = "https://data.aino.io/rest/v2.0/transaction";
my $api_key = "";
my $use_fork = 0;
my $gzip_enabled = 1;
my $proxy_address;

my %fields = ();


sub print_usage {
    print  <<"STOPPA";
Usage:  $0 [options]

Options:
    --to            Sets 'to' application (mandatory)
    --from          Sets 'from' application (mandatory)
    --status        Sets status (success,failure,unknown) (mandatory)
    --apikey        Sets API key (mandatory)
    --message       Sets message
    --operation     Sets business operation
    --flowId        Sets flow id. Also known as correlation id.
    --ids           Sets ids (idType=id1,id2,id3)
    --metadata      Sets metadata (key=value)
    --payloadType   Sets payload type
    --fork          Sends the HTTP request in background process
    --no_gzip       Disable gzipping of the payload (enabled by default)
    --proxy         Sets the proxy server to use


Example:
    ./$0 \\
        --from "application 1" \\
        --to "application 2" \\
        --status success \\
        --apikey "APIKEYHERE" \\
        --ids "InvoiceNumbers=12412311,12355991"
        --no_gzip
        --proxy "http://localhost:3128"

STOPPA
    exit(0);
}

sub check_mandatory_parameter {
    shift;
    my $var = shift;
    my $name = shift;

    if(!defined $var) {
        print_usage();
        print "Parameter '" . $name . "' not supplied! Quitting.\n";
        exit(-1);
    }
}

sub id_handler {
    my ($opt_name, $opt_value) = @_;
    my ($type, $values) = split('=', $opt_value, 2);
    my @vals = split(',', $values);
    my %id_hash = (idType => $type, values => \@vals);
    push @{$fields{ids}}, \%id_hash;
}

sub meta_handler {
    my ($opt_name, $meta_name, $meta_value) = @_;
    my %meta = (name => $meta_name, value => $meta_value);
    push @{$fields{metadata}}, \%meta;
}

sub fork_handler {
    $use_fork = 1;
}

sub apikey_handler {
    my ($opt_name, $apikey) = @_;
    $api_key = $apikey;
}

sub proxy_handler {
  my ($opt_name, $proxy_addr) = @_;
  $proxy_address = $proxy_addr;
}

sub gzip_handler {
    $gzip_enabled = 0;
}

GetOptions(
    \%fields,
    'from=s',
    'to=s',
    'message=s',
    'status=s',
    'payloadType=s',
    'flowId=s',
    'operation=s',
    'proxy=s' => \&proxy_handler,
    'ids=s@' => \&id_handler,
    'metadata=s%' => \&meta_handler,
    'fork' => \&fork_handler,
    'apikey=s' => \&apikey_handler,
    'help' => \&print_usage,
    'no_gzip' => \&gzip_handler) or print_usage;

check_mandatory_parameter(%fields{from}, 'from');
check_mandatory_parameter(%fields{to}, 'to');
check_mandatory_parameter(%fields{status}, 'status');

my $msg = Aino::Lib->new_aino_transaction();

foreach my $key (keys %fields) {
    $msg->set($key, $fields{$key});
}

if (defined $proxy_address) {
    Aino::Lib->set_proxy_addr($proxy_address);
}

Aino::Lib->set_api_key($api_key);
Aino::Lib->set_gzip_enabled($gzip_enabled);
Aino::Lib->send_transaction($msg, $use_fork);
