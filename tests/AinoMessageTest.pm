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

package Aino::Message::Test;

use Test::More;
use Time::HiRes qw/gettimeofday/;
use Data::Dumper qw(Dumper);
use Test::Deep::NoTest;
use File::Basename;


# Used to check generated timestamp
my $timestamp_before = int (gettimeofday * 1000);

require "AinoMessage.pm";

my $message = Aino::Message->new;

sub found_helper {
    my ($haystack) = @_;
    return sub {
        my $needle = shift;
        foreach my $x (@{$haystack}) {
            if(ref($x) eq 'HASH') {
                if(eq_deeply($x, $needle)) {
                    return 1;
                }
            } else {
                if($x == $needle) { return 1; }
            }
        }
        return 0;
    }
}

sub timestamp_tests {
    # Timestamp field
    my $timestamp_now = int (gettimeofday * 1000);
    ok(defined $message->get('timestamp'), 'Timestamp is set!');
    ok($message->get('timestamp') <= $timestamp_now && $message->get('timestamp') >= $timestamp_before, "Timestamp is in correct range.");
}

sub plain_field_tests {
    # Message field
    ok(!defined $message->get('message'), 'Message field is not defined before setting it.');

    $message->set('message', "This is test message123!&");
    ok(defined $message->get('message'), 'Message is defined after setting it.');
    ok($message->get('message') eq 'This is test message123!&', 'Message is the same on as set.');
}

sub setter_tests {
    my $msg = Aino::Message->new;

    # set_message
    ok(!defined $msg->get('message'), 'No message defined');
    $msg->set_message('This is message9;');
    ok($msg->get('message') eq 'This is message9;', 'Message defined after set_message()');

    # set_operation
    ok(!defined $msg->get('operation'), 'No operation defined');
    $msg->set_operation('Operation 9');
    ok($msg->get('operation') eq 'Operation 9', 'Operation correct after set_operation()');

    # set_to
    ok(!defined $msg->get('to'), 'No "to" defined.');
    $msg->set_to('ToApplication');
    ok($msg->get('to') eq 'ToApplication', 'To application set correctly after set_to()');

    # set_from
    ok(!defined $msg->get('from'), 'No "from" defined.');
    $msg->set_from('Application of From');
    ok($msg->get('from') eq 'Application of From', 'From application set correctly after set_from()');

    # set_flowId
    #ok(index($msg->get('flowId'), 'perl-agent-') == 0, 'FlowId is defined even if not set.');
    #$msg->set_flowId('Flowing like a river');
    #ok(index($msg->get('flowId'), 'perl-agent-') < 0, 'FlowId is defined even if not set.');
    #ok($msg->get('flowId') eq 'Flowing like a river', 'Flow id is set correctly after set_flowId()');
}

sub test_flow_ids {
    my $msg = Aino::Message->new;
    my $msg2 = Aino::Message->new;
    $msg2->set_to('to');
    $msg2->set_from('from');
    my $msg2_json = $msg2->to_json;

    ok(index($msg2_json, 'perl-agent-'), 'flowId is set automagically if user did not provide it');


    ok(!defined $msg->get('flowId'), 'flowId is not defined by default');
    $msg->init_flow_id();
    ok(defined $msg->get('flowId'), 'flowId is defined after init_flow_id call');
    ok(index($msg->get('flowId'), 'perl-agent' == 0), 'flowId is set to string starting with "perl-agent"');

    my $msg3 = Aino::Message->new;
    ok($msg3->get('flowId') eq $msg->get('flowId'), 'flowIds match in different messages after init_flow_id');

    $msg->clear_flow_id();
    ok(!defined $msg->get('flowId'), 'flowId is not defined after clear_flow_id call');
}

sub id_field_tests {
    # Add ids
    my ($idTypeName, @ids) = @_;

    $message->add_ids($idTypeName, \@ids);

    ok($message->get('ids'), 'ids field is defined');

    # Get latest ids from message
    $ids_from_message = $message->get('ids');
    $id_element = $ids_from_message->[$#ids_from_message];

    ok($id_element->{idType} eq $idTypeName, "idTypeName equals $idTypeName");

    my $finder = &found_helper( $id_element->{values} );

    foreach my $val (@ids) {
        ok(&$finder($val), "Contains id $val");
        ok(!&$finder($val+99), "Does not contain id $val+99");
    }

    ok(scalar @{$id_element->{values}} == scalar @ids, 'Correct amount of ids');
}

sub meta_field_tests {
    my (@to_add) = @_;
    foreach my $key_value (@to_add) {
        $message->add_metadata($key_value->{'name'}, $key_value->{'value'});
    }
    my $meta_fields = $message->get('metadata');

    ok($meta_fields->[0]->{'name'} eq 'agent', 'Metadata contains agent key');
    ok($meta_fields->[0]->{'value'} eq 'PerlAgent', 'Metadata agent key corresponds to "PerlAgent" value.');

    my $finder = &found_helper(\@to_add);

    for (my $field_num = 1; $field_num < scalar @{$meta_fields}; $field_num++) {
        foreach my $key_value ($meta_fields->[$field_num]) {
            ok(&$finder(
                    {name => $key_value->{'name'}, value => $key_value->{'value'}}),
                    "Searching hash with name: $key_value->{'name'} and value: $key_value->{'value'}");
        }
    }

    ok(!&$finder({name => "asdas", value => "das!"}), "Should not find invalid data.");

}

timestamp_tests;
plain_field_tests;
id_field_tests 'idTestType', (1, 12, 23, 34, 45, 56);
id_field_tests 'test2Type', ('432av', 'ägräs', '423,rw');
meta_field_tests ({name => "field1", value => "value1"}, {name => "field2", value => "value2"});
test_flow_ids;
setter_tests;