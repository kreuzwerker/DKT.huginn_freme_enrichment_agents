module Agents
  class FremeFilterAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include FremeNifApiAgentConcern

    default_schedule 'never'

    description <<-MD
      The `FremeFilterAgent` allows to execute a certain filter against a RDF graph sent as post body or as value of the NIF input parameter. For more information and a list of available filters, see the [Simply FREME output using SPARQL filters](http://api.freme-project.eu/doc/current/knowledge-base/freme-for-api-users/filtering.html) article.

      The Agent accepts all configuration options of the `/toolbox/convert/documents` endpoint as of September 2016, have a look at the [offical documentation](https://freme-project.github.io/api-doc/full.html#!/Toolbox%2FPostprocessing-Filter/post_toolbox_convert_documents_name) if you need additional information.

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `base_url` allows to customize the API server when hosting the FREME services elswhere.

      #{freme_auth_token_description}

      `body` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the data to be send to the API.

      `body_format` specify the content-type of the data in `body`

      `outformat` requested RDF serialization format of the output

      `name` name of filter to execute against, [the official documentation](http://api.freme-project.eu/doc/current/api-doc/full.html#!/Toolbox/get_toolbox_convert_manage) has a list of all available filters.

      #{common_nif_agent_fields_description}
    MD

    def default_options
      {
        'base_url' => 'http://api.freme-project.eu/current/',
        'body' => '{{ body }}',
        'body_format' => 'text/turtle',
        'outformat' => 'text/turtle',
        'name' => '',
      }
    end

    form_configurable :base_url
    form_configurable :auth_token
    form_configurable :body
    form_configurable :body_format, type: :array, values: ['text/n3', 'text/turtle', 'application/ld+json', 'application/n-triples', 'application/rdf+xml']
    form_configurable :outformat, type: :array, values: ['text/comma-separated-values', 'text/xml', 'application/json', 'application/ld+json', 'text/turtle', 'text/n3', 'application/n-triples', 'application/rdf+xml']
    form_configurable :name, roles: :completable
    common_nif_agent_fields

    def validate_options
      errors.add(:base, "body needs to be present") if options['body'].blank?
      errors.add(:base, "base_url needs to be present") if options['base_url'].blank?
      errors.add(:base, "base_url needs to end with a trailing '/'") unless options['base_url'].end_with?('/')
      errors.add(:base, "name needs to be present") if options['name'].blank?
      validate_web_request_options!
    end

    def complete_name
      response = faraday.run_request(:get, URI.join(interpolated['base_url'], 'toolbox/convert/manage'), nil, auth_header.merge({ 'Accept' => 'application/json'}))
      return [] if response.status != 200

      JSON.parse(response.body).map { |filter| { text: "#{filter['name']}", id: filter['name'], description: filter['description'] } }
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        nif_request!(mo, ['outformat'], URI.join(mo['base_url'], 'toolbox/convert/documents/', mo['name']), event: event)
      end
    end
  end
end
