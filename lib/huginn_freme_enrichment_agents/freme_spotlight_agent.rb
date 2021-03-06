module Agents
  class FremeSpotlightAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include FremeNifApiAgentConcern
    include FremeFilterable

    default_schedule 'never'

    description <<-MD
      The `FremeFilterAgent`  enriches text content with entities gathered from various datasets by the DBPedia-Spotlight Engine.

      The Agent accepts all configuration options of the `/e-entity/dbpedia-spotlight/documents` endpoint as of September 2016, have a look at the [offical documentation](https://freme-project.github.io//api-doc/full.html#!/e-Entity/executeSpotlightNer) if you need additional information.

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `base_url` allows to customize the API server when hosting the FREME services elswhere.

      #{freme_auth_token_description}

      `body` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the data to be send to the API.

      `body_format` specify the content-type of the data in `body`

      `outformat` requested RDF serialization format of the output#{filterable_outformat_description}

      `prefix` controls the url of rdf resources generated from plaintext. Has default value "http://freme-project.eu/".

      `numLinks` The number of links from a knowledge base returned for each entity. Note that for some entities it might returned less links than requested. This might be due to the low number of links available. The maximum number of links that can be returned is 5.

      `language` language of the source data

      `confidence` Setting a high confidence threshold instructs DBpedia Spotlight to avoid incorrect annotations as much as possible at the risk of losing some correct ones. A confidence value of 0.7 will eliminate 70% of incorrectly disambiguated test cases. The range of the confidence parameter is between 0 and 1. Default is 0.3.

      #{filterable_description}

      #{common_nif_agent_fields_description}
    MD

    def default_options
      {
        'base_url' => 'http://api.freme-project.eu/current/',
        'body' => '{{ body }}',
        'body_format' => 'text/plain',
        'outformat' => 'text/turtle',
        'prefix' => '',
        'language' => 'en',
        'numLinks' => '1',
        'confidence' => '0.3'
      }
    end

    form_configurable :base_url
    form_configurable :auth_token
    form_configurable :body
    form_configurable :body_format, type: :array, values: ['text/plain', 'text/xml', 'text/html', 'text/n3', 'text/turtle', 'application/ld+json', 'application/n-triples', 'application/rdf+xml', 'application/x-xliff+xml', 'application/x-openoffice']
    form_configurable :outformat, type: :array, values: ['text/turtle', 'application/ld+json', 'text/n3', 'application/n-triples', 'application/rdf+xml', 'text/html', 'text/xml', 'application/x-xliff+xml', 'application/x-openoffice']
    form_configurable :prefix
    form_configurable :language, type: :array, values: ['en']
    form_configurable :numLinks
    form_configurable :confidence
    filterable_field
    common_nif_agent_fields

    def validate_options
      errors.add(:base, "body needs to be present") if options['body'].blank?
      errors.add(:base, "base_url needs to be present") if options['base_url'].blank?
      errors.add(:base, "base_url needs to end with a trailing '/'") unless options['base_url'].end_with?('/')
      errors.add(:base, "number needs to be greater than 0 and less than or equal to 5") unless options['numLinks'].blank? || (1..5) === options['numLinks'].to_i
      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        nif_request!(mo, ['outformat', 'prefix', 'language', 'numLinks','confidence'], URI.join(mo['base_url'], 'e-entity/dbpedia-spotlight/documents'), event: event)
      end
    end
  end
end
