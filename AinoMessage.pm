
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


package Aino::Message;
use strict;
use warnings;
use feature 'state';

use JSON qw\\;
use Time::HiRes qw/gettimeofday/;

our @mandatory = ('to', 'from', 'status');

state $flowId;

sub new {
    my $class = shift;
    my @meta = ({ name=> 'agent', value => 'PerlAgent'}); # TODO version number mayhaps
    return bless {'data' => {'timestamp' => int (gettimeofday * 1000), 'metadata' => \@meta}}, $class;
}

sub init_flow_id {
    $flowId = _get_new_flow_id();
}

sub clear_flow_id {
    $flowId = undef;
}

sub _get_new_flow_id {
    'perl-agent-' . int (gettimeofday * 1000);
}


sub set {
    my ($self, $field, $val) = @_;

    #if($field eq 'flowId') {
    #    $flowId = $val;
    #}

    $self->{data}->{$field} = $val;
}

sub get {
    my ($self, $field) = @_;

    if($field eq 'flowId' && !defined $self->{data}->{flowId}) {
        return $flowId;
    }

    return $self->{data}->{$field};
}

sub set_message {
    my ($self, $value) = @_;
    $self->set('message', $value);

    return $self;
}

sub set_flowId {
    my ($self, $value) = @_;
    $self->set('flowId', $value);

    return $self;
}

sub set_to {
    my ($self, $value) = @_;
    $self->set('to', $value);

    return $self;
}

sub set_from {
    my ($self, $value) = @_;
    $self->set('from', $value);

    return $self;
}

sub set_status {
    my ($self, $value) = @_;
    $self->set('status', $value);

    return $self;
}

sub set_operation {
    my ($self, $value) = @_;
    $self->set('operation', $value);

    return $self;
}

sub set_payloadType {
    my ($self, $value) = @_;
    $self->set('payloadType', $value);

    return $self;
}

sub add_ids {
    my ($self, $idType, $ids) = @_;
    my %h = (idType => $idType, values => $ids);

    push @{$self->{data}->{ids}}, \%h;
}

sub add_metadata {
    my ($self, $name, $value) = @_;
    my %h = (name => $name, value => $value);

    push @{$self->{data}->{metadata}}, \%h;
}

sub to_json {
    my $self = shift;
    if(!defined $self->{data}->{status}) {
        $self->{data}->{status} = 'unknown';
    }

    # Use the generated flow id, if user did not specify one.
    if(!defined $self->{data}->{flowId}) {
        if(defined $flowId) {
            $self->{data}->{flowId} = $flowId;
        } else {
            $self->{data}->{flowId} = _get_new_flow_id();
        }
    }

    foreach my $mandatory_field (@mandatory) {
        if(!defined $self->{data}->{$mandatory_field}) {
            print STDERR "REQUIRED FIELD MISSING FROM Aino::Message: $mandatory_field\n";
        }
    }

    return '{"transactions": [' . JSON::to_json($self->{data}) . "]}";
}


1