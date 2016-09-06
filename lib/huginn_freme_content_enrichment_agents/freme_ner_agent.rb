module Agents
  class FremeNerAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include NifApiAgentConcern
    include FremeFilterable

    default_schedule 'never'

    description <<-MD
      The `FremeNerAgent` (Freme Named Entity Recognition) enriches text content with entities gathered from various datasets by the DBPedia-Spotlight Engine. The service accepts plaintext or text sent as NIF document. The text of the nif:isString property (attached to the nif:Context document) will be used for processing.

      The Agent accepts all configuration options of the `/e-entity/freme-ner/documents` endpoint as of version `0.6`, have a look at the [official documentation](http://api.freme-project.eu/doc/0.6/api-doc/full.html#!/e-Entity/executeFremeNel) if you need additional information

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `base_url` allows to customize the API server when hosting the FREME services elsewhere, make sure to include the API version.

      #{freme_auth_token_description}

      `body` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the data to be send to the API.

      `body_format` specify the content-type of the data in `body`

      `outformat` requested RDF serialization format of the output#{filterable_outformat_description}

      `prefix` controls the url of rdf resources generated from plaintext. Has default value "http://freme-project.eu/".

      `language` language of the source data

      `dataset` indicates the dataset used for entity linking which includes a list of entities and associated labels.

      `mode` This parameter allows to produce only partly results of named entity recognition. This can speed up computation time. Spotting and classification are relatively fast operations, whereas linking is a computationally expensive operation. When "link" is given as the parameter and the given "informat" or "Content-Type" is NIF, this service expects NIF data with entity mentions, i.e. anchorOf, beginIndex, endIndex etc. are given and it does only entity linking. When "link" is given as the parameter and the given "informat" or "Content-Type" is plain text, this service interprets the entire input as a single Entity and does entity linking for that specific entity. Note that "all" is equivalent to "spot,link,classify". The order of the modes are irrelevant, i.e. "spot,link,classify" is equivalent to "spot,classify,link".

      `domain` Takes as input a domain ID, and it only returns entities from this domain. The domain IDs are from the [TaaS domain classification system](https://term.tilde.com/domains). For example, the sports domain is identified with the TaaS-2007 ID. Note that the IDs are case-sensitive. More information about the domain parameter in [FREME NER knowledge-base](http://api.freme-project.eu/doc/0.6/knowledge-base/freme-for-api-users/freme-ner.html).

      `types` Takes as input list of one or more entity types separated by a comma. The types are URLs of ontology classes and they should be encoded. The result is a list of extracted entities with these types. More information about the types parameter in [FREME NER knowledge-base](http://api.freme-project.eu/doc/0.6/knowledge-base/freme-for-api-users/freme-ner.html).

      `numLinks` Using the numLinks parameter one can specify the maximum number of links to be assigned to an entity. By default only one link is returned. The maximum possible number for this parameter is 5.

      #{filterable_description}
    MD

    def default_options
      {
        'base_url' => 'http://api.freme-project.eu/0.6/',
        'body' => '{{ data }}',
        'body_format' => 'text/plain',
        'outformat' => 'turtle',
        'language' => 'en',
        'mode' => 'all',
        'numLinks' => '1'
      }
    end

    form_configurable :base_url
    form_configurable :auth_token
    form_configurable :body
    form_configurable :body_format, type: :array, values: ['text/plain', 'text/xml', 'text/html', 'text/n3', 'text/turtle', 'application/ld+json', 'application/n-triples', 'application/rdf+xml', 'application/x-xliff+xml', 'application/x-openoffice']
    form_configurable :outformat, type: :array, values: ['turtle', 'json-ld', 'n3', 'n-triples', 'rdf-xml', 'text/html', 'text/xml', 'application/x-xliff+xml', 'application/x-openoffice', 'csv']
    form_configurable :prefix
    form_configurable :language, type: :array, values: ['en','de','nl','fr','it','es','ru']
    form_configurable :dataset, roles: :completable
    form_configurable :mode, type: :array, values: ['all', 'spot', 'spot,classify', 'spot,link', 'spot,link,classify', 'link']
    form_configurable :domain
    form_configurable :types
    form_configurable :numLinks
    filterable_field

    def validate_options
      errors.add(:base, "body needs to be present") if options['body'].blank?
      errors.add(:base, "base_url needs to be present") if options['base_url'].blank?
      errors.add(:base, "base_url needs to end with a trailing '/'") unless options['base_url'].end_with?('/')
      errors.add(:base, "dataset needs to be present") if options['dataset'].blank?
      errors.add(:base, "number needs to be greater than 0 and less than or equal to 5") unless options['numLinks'].blank? || (1..5) === options['numLinks'].to_i
      validate_web_request_options!
    end

    def complete_dataset
      response = faraday.run_request(:get, URI.join(interpolated['base_url'], 'e-entity/freme-ner/datasets'), nil, auth_header.merge({'Accept' => 'application/json'}))
      return [] if response.status != 200

      JSON.parse(response.body).map { |dataset| { text: "#{dataset['name']}: #{dataset['description']}", id: dataset['name'] } }
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        nif_request!(mo, ['outformat', 'prefix', 'language', 'dataset', 'mode', 'domain', 'types', 'numLinks'], URI.join(mo['base_url'], 'e-entity/freme-ner/documents'))
      end
    end
  end
end
