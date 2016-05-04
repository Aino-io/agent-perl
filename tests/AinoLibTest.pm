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


package Aino::Lib::Test;

use Test::More;
use Time::HiRes qw/gettimeofday/;

require 'AinoLib.pm';

# Check that lib returns Aino::Message
ok(ref(Aino::Lib->new_aino_transaction()) eq 'Aino::Message', 'Aino::Lib->new_aino_transaction returns correct');

# Check api address stuff
ok($Aino::Lib::api_address eq 'https://data.aino.io/rest/v2.0/transaction', 'Aino::Lib has correct api address by default');

Aino::Lib->set_api_address('http://invalid.address.com');

ok($Aino::Lib::api_address ne 'https://data.aino.io/rest/v2.0/transaction', 'Aino::Lib api address has changed');
ok($Aino::Lib::api_address eq 'http://invalid.address.com', 'Aino::Lib address has changed to correct one');

# Check apikey stuff
ok(!defined $Aino::Lib::api_key, 'Api key is not set by default');
Aino::Lib->set_api_key('API_KEY_IN_TESTING!');
ok($Aino::Lib::api_key eq 'API_KEY_IN_TESTING!', 'Api key is set after set_api_key()');

# Check gzipping
ok($Aino::Lib::gzip_enabled == 1, 'Gzip is enabled by default');
Aino::Lib->set_gzip_enabled(0);
ok($Aino::Lib::gzip_enabled == 0, 'Gzipping can be disabled');

my $msg = Aino::Lib->new_aino_transaction();
$msg->set_to('to1');
$msg->set_from('from1');
my $msg_as_json = $msg->to_json();

ok($msg_as_json eq Aino::Lib->get_payload($msg), 'When gzipping is disabled, payload is not gzipped');

my $msg_gzipped = Aino::Lib->get_payload($msg);
Aino::Lib->set_gzip_enabled(1);
ok(!($msg_as_json eq Aino::Lib->get_payload($msg)), 'When gzipping is enabled, payload is gzipped');

# Check that forking send returns immediately..
my $timestamp1 = int (gettimeofday * 1000);
Aino::Lib->send_transaction($msg, 1);
my $timestamp2 = int (gettimeofday * 1000);
ok($timestamp1 + 7 > $timestamp2, 'Aino::Lib->send_transaction took less than 7 milliseconds'); # Magic number!

