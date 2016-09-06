module Agents
  class FremeTerminologyAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include NifApiAgentConcern
    include FremeFilterable

    default_schedule 'never'

    description <<-MD
      The `FremeTerminologyAgent` annotate text with terminology information using Tilde Terminology service.

      The Agent accepts all configuration options of the `/e-terminology/tilde` endpoint as of version `0.6`, have a look at the [offical documentation](http://api.freme-project.eu/doc/0.6/api-doc/full.html#!/e-Terminology/e_terminology) if you need additional information

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `base_url` allows to customize the API server when hosting the FREME services elswhere, make sure to include the API version.

      #{freme_auth_token_description}

      `body` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the data to be send to the API.

      `body_format` specify the content-type of the data in `body`

      `outformat` requested RDF serialization format of the output#{filterable_outformat_description}

      `prefix` controls the url of rdf resources generated from plaintext. Has default value "http://freme-project.eu/".

      `source_lang` source language, e.g. "de","en". Language of submitted text. A list of supported language codes is [here](https://term.tilde.com/resources).

      `target_lang` target language, e.g. "de", "en". Language for targeted terms. A list of supported language codes is [here](https://term.tilde.com/resources).

      `collection` collection id from [https://term.tilde.com](https://term.tilde.com) portal. If filled then annotates only with terms from that collection

      `mode` Whether the result must contain full terminology information or only term annotations with references to the full information

      `domain` If given - it filters out by domain proposed terms. Available domains here: [https://term.tilde.com/domains](https://term.tilde.com/domains) (should pass just ID, eg, TaaS-1001, that means Agriculture)

      `key` A private key to access private and not publicly available translation systems. Key can be created by contacting [Tilde](http://www.tilde.com/mt/contacts) team. Optional, if omitted then translates with public systems

      #{filterable_description}
    MD

    def default_options
      {
        'base_url' => 'http://api.freme-project.eu/0.6/',
        'body' => '{{ data }}',
        'body_format' => 'text/plain',
        'outformat' => 'turtle',
        'prefix' => '',
        'source_lang' => 'en',
        'target_lang' => 'en',
        'collection' => '',
        'mode' => 'full',
        'domain' => '',
        'key' => '',
      }
    end

    form_configurable :base_url
    form_configurable :auth_token
    form_configurable :body
    form_configurable :body_format, type: :array, values: ['text/plain', 'text/xml', 'text/html', 'text/n3', 'text/turtle', 'application/ld+json', 'application/n-triples', 'application/rdf+xml', 'application/x-xliff+xml', 'application/x-openoffice']
    form_configurable :outformat, type: :array, values: ['turtle', 'json-ld', 'n3', 'n-triples', 'rdf-xml', 'text/html', 'text/xml', 'application/x-xliff+xml', 'application/x-openoffice', 'csv']
    form_configurable :prefix
    form_configurable :source_lang, type: :array, values: %w{bg hr cs da nl en et fi fr de el hu ga it lv lt mt pl pt ro ru sk sl es sv tr}
    form_configurable :target_lang, type: :array, values: %w{bg hr cs da nl en et fi fr de el hu ga it lv lt mt pl pt ro ru sk sl es sv tr}
    form_configurable :collection, roles: :completable
    form_configurable :mode, type: :array, values: ['full', 'annotation']
    form_configurable :domain
    form_configurable :key
    filterable_field

    def validate_options
      errors.add(:base, "body needs to be present") if options['body'].blank?
      errors.add(:base, "base_url needs to be present") if options['base_url'].blank?
      errors.add(:base, "base_url needs to end with a trailing '/'") unless options['base_url'].end_with?('/')
      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        nif_request!(mo, ['outformat', 'prefix', 'source_lang', 'target_lang','collection', 'mode', 'domain', 'key',], URI.join(mo['base_url'], 'e-terminology/tilde'))
      end
    end
  end
end
