# Perl Agent for Aino.io

![Build status](https://circleci.com/gh/Aino-io/agent-perl.svg?style=shield&circle-token=9965fe818fcc8937901cbf249cd9d07707ab1138)

Perl implementation of Aino.io logging agent

## What is [Aino.io](http://aino.io) and what does this Agent have to do with it?

[Aino.io](http://aino.io) is an analytics and monitoring tool for integrated enterprise applications and digital business processes. Aino.io can help organizations manage, develop, and run the digital parts of their day-to-day business. Read more from our [web pages](http://aino.io).

Aino.io works by analyzing transactions between enterprise applications and other pieces of software. This Agent helps to store data about the transactions to Aino.io platform using Aino.io Data API (version 2.0). See [API documentation](http://www.aino.io/api) for detailed information about the API.


## Technical requirements
* Perl 5

Agent requires some external libraries:
* `LWP::Protocol::https`
* `Proc::Daemon`

## Example usage

#### Minimal example (only required fields)

```perl
require "path/to/aino/AinoLib.pm";

Aino::Lib->set_api_key('YOUR API KEY HERE');

my $message = Aino::Lib->new_aino_transaction();

$message->set_to('To application')
        ->set_from('From application')
        ->set_status('success')
        ->set_flowId('aka.correlationId')

Aino::Lib->send_transaction($message, $fork);
```

#### Full example

```perl
require "path/to/aino/AinoLib.pm";

Aino::Lib->set_api_key('YOUR API KEY HERE');
Aino::Lib->set_gzip_enabled(1);

my $message = Aino::Lib->new_aino_transaction();

$message->set_message('message')
        ->set_to('To application')
        ->set_from('From application')
        ->set_status('success')
        ->set_flowId('aka.correlationId')
        ->set_operation('Business operation 1')
        ->set_payloadType('Invoices');

$message->add_ids('Invoice number', (55123, 88634, 55111));
$message->add_metadata('key', 'value');

my $fork = 1;   # Fork the sending to background process with 1.
                # When set to 0, does not fork and returns when the HTTP request is done

Aino::Lib->send_transaction($message, $fork);
```

This agent can also be used from command line.

##### Logging from command line

```bash
perl aino-agent.pl
    --from "From application" \
    --to "To application" \
    --status "failure" \
    --apikey "YOU API KEY HERE" \
```

# What to use as flow ID
The flow ID, also known as correlation ID or correlation key is an identifier that allows aino
to group several aino transaction invocations into a single transaction.

If user does not set flow Id, it will be automatically generated.
By calling `Aino::Lib->init_flow_id`, all subsequent messages will have the same flow id.
This can be overridden by setting the messages flow id manually:
```perl
$msg->set_flowId('desired flow id');
```
Calling `Aino::Lib->clear_flow_id` will clear the flow id set in `Aino::Lib->init_flow_id`.

## Contributing

### Technical Requirements
Same as above, but also this for running tests:
* `Test::Deep::NoTest`

### Contributors

* [Jussi Mikkonen](https://github.com/jussi-mikkonen)
* [Ville Harvala](https://github.com/vharvala)

## [License](LICENSE)

Copyright &copy; 2016 [Aino.io](http://aino.io). Licensed under the [Apache 2.0 License](LICENSE).
