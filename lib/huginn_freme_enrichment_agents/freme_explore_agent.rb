module Agents
  class FremeExploreAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include FremeNifApiAgentConcern
    include FremeFilterable

    default_schedule 'never'

    description <<-MD
      The `FremeExploreAgent` can retrieve description of a resource from a given endpoint. The endpoint can be SPARQL or Linked Data Fragments endpoint.

      The Agent accepts all configuration options of the `/e-link/explore` endpoint as of September 2016, have a look at the [offical documentation](http://api.freme-project.eu/doc/current/api-doc/full.html#!/e-Link/explore) if you need additional information.

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `base_url` allows to customize the API server when hosting the FREME services elswhere.

      #{freme_auth_token_description}

      `outformat` requested RDF serialization format of the output (required)#{filterable_outformat_description}.

      `resource` a URI of the resource which should be described (required).

      `endpoint` a URL of the endpoint which should be used to retrieve info about the resource.

      `endpoint_type` the type of the endpoint (required).

      #{filterable_description}

      `merge` set to true to retain the received payload and update it with the extracted result
    MD

    def default_options
      {
        'base_url' => 'http://api.freme-project.eu/current/',
        'outformat' => 'text/turtle',
        'endpoint' => '',
        'resource' => '',
        'endpoint_type' => 'sparql'
      }
    end

    form_configurable :base_url
    form_configurable :auth_token
    form_configurable :outformat, type: :array, values: ['application/ld+json', 'text/turtle', 'text/n3', 'application/n-triples', 'application/rdf+xml']
    form_configurable :resource
    form_configurable :endpoint
    form_configurable :endpoint_type, type: :array, values: ['sparql', 'ldf']
    filterable_field
    form_configurable :merge, type: :boolean

    def validate_options
      errors.add(:base, "base_url needs to be present") if options['base_url'].blank?
      errors.add(:base, "base_url needs to end with a trailing '/'") unless options['base_url'].end_with?('/')
      errors.add(:base, "resource needs to be present") if options['resource'].blank?
      errors.add(:base, "endpoint needs to be present") if options['endpoint'].blank?
      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        nif_request!(mo, ['outformat', 'resource', 'endpoint', 'endpoint_type'], URI.join(mo['base_url'], 'e-link/explore'), event: event)
      end
    end
  end
end
