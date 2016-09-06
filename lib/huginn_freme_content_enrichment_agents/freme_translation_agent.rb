module Agents
  class FremeTranslationAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include NifApiAgentConcern
    include FremeFilterable

    default_schedule 'never'

    description <<-MD
      The `FremeTranslationAgent` translates text using Tilde Translation service.

      The Agent accepts all configuration options of the `/e-translation/tilde` endpoint as of version `0.6`, have a look at the [offical documentation](http://api.freme-project.eu/doc/0.6/api-doc/full.html#!/e-Terminology/e_terminology) if you need additional information

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `base_url` allows to customize the API server when hosting the FREME services elswhere, make sure to include the API version.

      #{freme_auth_token_description}

      `body` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the data to be send to the API.

      `body_format` specify the content-type of the data in `body`

      `outformat` requested RDF serialization format of the output#{filterable_outformat_description}

      `source_lang` source language, e.g. "en". A list of available language pairs is  [here](https://services.tilde.com/translationsystems).

      `target_lang` target language, e.g. "de". A list of available language pairs is [here](https://services.tilde.com/translationsystems).

      `key` A private key to access private and not publicly available translation systems. Key can be created by contacting [Tilde](http://www.tilde.com/mt/contacts) team. Optional, if omitted then translates with public systems

      `domain` specify domain of translation system. List of supported domains and language pairs can be found [here](https://services.tilde.com/translationsystems).

      `system` select translation system by ID [an alternative to source, target language and domain selection]. ID of public translation system can be retrieved at [https://services.tilde.com/translationsystems](https://services.tilde.com/translationsystems) or private system ID can be found at portal [http://tilde.com/mt](http://tilde.com/mt) with authentication [optional, if omitted then source and target languages and also domain parameters are used]

      #{filterable_description}
    MD

    def default_options
      {
        'base_url' => 'http://api.freme-project.eu/0.6/',
        'body' => '{{ data }}',
        'body_format' => 'text/plain',
        'outformat' => 'turtle',
        'source_lang' => 'en',
        'target_lang' => 'de',
        'key' => '',
        'domain' => '',
        'system' => ''
      }
    end

    form_configurable :base_url
    form_configurable :auth_token
    form_configurable :body
    form_configurable :body_format, type: :array, values: ['text/plain', 'text/xml', 'text/html', 'text/n3', 'text/turtle', 'application/ld+json', 'application/n-triples', 'application/rdf+xml', 'application/x-xliff+xml', 'application/x-openoffice']
    form_configurable :outformat, type: :array, values: ['turtle', 'json-ld', 'n3', 'n-triples', 'rdf-xml', 'text/html', 'text/xml', 'application/x-xliff+xml', 'application/x-openoffice', 'csv']
    form_configurable :source_lang, type: :array, values: %w{bg hr cs da nl en et fi fr de el hu ga it lv lt mt pl pt ro ru sk sl es sv tr}
    form_configurable :target_lang, type: :array, values: %w{bg hr cs da nl en et fi fr de el hu ga it lv lt mt pl pt ro ru sk sl es sv tr}
    form_configurable :key
    form_configurable :domain
    form_configurable :system
    filterable_field

    def validate_options
      errors.add(:base, "body needs to be present") if options['body'].blank?
      errors.add(:base, "base_url needs to be present") if options['base_url'].blank?
      errors.add(:base, "base_url needs to end with a trailing '/'") unless options['base_url'].end_with?('/')
      errors.add(:base, "source_lang needs to be present") if options['source_lang'].blank?
      errors.add(:base, "target_lang needs to be present") if options['target_lang'].blank?
      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        nif_request!(mo, ['outformat', 'prefix', 'source_lang', 'target_lang', 'key', 'domain', 'system'], URI.join(mo['base_url'], 'e-terminology/tilde'))
      end
    end
  end
end
