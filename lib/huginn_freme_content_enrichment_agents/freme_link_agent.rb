module Agents
  class FremeLinkAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include NifApiAgentConcern
    include FremeFilterable

    default_schedule 'never'

    description <<-MD
      The `FremeLinkAgent` accepts a NIF document (with annotated entities) and performs enrichment with pre-defined templates.

      The Agent accepts all configuration options of the `/e-link/documents` endpoint as of version `0.6`, have a look at the [offical documentation](http://api.freme-project.eu/doc/0.6/api-doc/full.html#!/e-Link/enrich) if you need additional information.

      The templates contain `fields` marked between three at-signs `@@@field-name@@@`. If a user, while calling the enrichment endpoint specifies an `unknown` parameter (not from the list above), then the values of that `unknown` parameters will be used to replace with the corresponding `field` in the query template.

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `base_url` allows to customize the API server when hosting the FREME services elsewhere, make sure to include the API version.

      #{freme_auth_token_description}

      `body` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the data to be send to the API.

      `body_format` specify the content-type of the data in `body`

      `outformat` requested RDF serialization format of the output#{filterable_outformat_description}

      `templateid` the ID of the template to be used for enrichment, [the official documentation](http://api.freme-project.eu/doc/0.6/api-doc/full.html#!/e-Link/getAllTemplates) has a list of all available templates.

      #{filterable_description}
    MD

    def default_options
      {
        'base_url' => 'http://api.freme-project.eu/0.6/',
        'body' => '{{ body }}',
        'body_format' => 'text/turtle',
        'outformat' => 'turtle',
        'templateid' => '',
      }
    end

    form_configurable :base_url
    form_configurable :auth_token
    form_configurable :body
    form_configurable :body_format, type: :array, values: ['text/n3', 'text/turtle', 'application/ld+json', 'application/n-triples', 'application/rdf+xml']
    form_configurable :outformat, type: :array, values: ['turtle', 'json-ld', 'n3', 'n-triples', 'rdf-xml', 'text', 'rdf-xml', 'csv']
    form_configurable :templateid, roles: :completable
    filterable_field

    def validate_options
      errors.add(:base, "body needs to be present") if options['body'].blank?
      errors.add(:base, "base_url needs to be present") if options['base_url'].blank?
      errors.add(:base, "base_url needs to end with a trailing '/'") unless options['base_url'].end_with?('/')
      errors.add(:base, "templateid needs to be present") if options['templateid'].blank?
      validate_web_request_options!
    end

    def complete_templateid
      response = faraday.run_request(:get, URI.join(interpolated['base_url'], 'e-link/templates'), nil, auth_header.merge({ 'Accept' => 'application/json'}))
      return [] if response.status != 200

      JSON.parse(response.body).map { |template| { text: "#{template['label'].presence || 'No label'}", description: template['description'], id: template['id'] } }
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        nif_request!(mo, ['outformat', 'templateid'], URI.join(mo['base_url'], 'e-link/documents'))
      end
    end
  end
end
