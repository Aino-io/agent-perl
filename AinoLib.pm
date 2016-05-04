
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


package Aino::Lib;
use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request::Common;
#use Data::Dumper qw(Dumper);
use File::Basename;
use Proc::Daemon;
my $dirname = dirname(__FILE__);

#require 'AinoMessage.pm';
require "$dirname/AinoMessage.pm";

our $userAgent = LWP::UserAgent->new();
our $api_address = "https://data.aino.io/rest/v2.0/transaction";
our $api_key;
our $gzip_enabled = 1;

sub new_aino_transaction {
    return Aino::Message->new;
}

sub init_flow_id {
    Aino::Message->init_flow_id;
}

sub clear_flow_id {
    Aino::Message->clear_flow_id;
}

sub set_gzip_enabled {
    my($self, $gzip) = @_;

    $gzip_enabled = $gzip;
}

sub set_api_address {
    my ($self, $addr) = @_;
    $api_address = $addr;
}

sub set_api_key {
    my ($self, $key) = @_;
    $api_key = $key;
}

sub get_payload {
    my ($self, $msg) = @_;
    my $payload;

    use IO::Compress::Gzip qw(gzip $GzipError) ;

    if($gzip_enabled) {
        gzip \$msg->to_json() => \$payload or die "failed to gzip: $GzipError\n";
        return $payload;
    }

    return $msg->to_json();
}

sub _get_request {
    my ($payload) = @_;
    my $req;

    if($gzip_enabled) {
        return POST  $api_address,
                     Content_Type => 'application/json',
                     Authorization => "apikey $api_key",
                     Content_Encoding => 'gzip',
                     Content => $payload;
    }

    POST  $api_address,
          Content_Type => 'application/json',
          Authorization => "apikey $api_key",
          Content => $payload;
}

sub send_transaction {
    my ($self, $msg, $use_fork) = @_;

    # Fork by default
    if(!defined $use_fork) {
        $use_fork = 1;
    }

    if(!defined $api_key) {
        print STDERR "API KEY NOT SET! Cannot send!\n";
        return;
    }

    if($use_fork) {
        print "Forking the send!";
        my $daemon = Proc::Daemon->new({work_dir => $dirname});
        my $pid = $daemon->Init;

        if($pid) {
            # Parent returns. Child continues.
            return;
        }
    }

    my $payload = $self->get_payload($msg);
    my $req = _get_request($payload);
    my $response = $userAgent->request($req);

    if($response->code ne 202) {
        print STDERR "Got non success response code: " . $response->code . " " . $response->message . "\n";
    }

    if($use_fork) {
        # We are child process here. We've done all we had to, let's exit!
        exit(0);
    }
}

1