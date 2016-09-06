module Agents
  class FremeNifConverterAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include NifApiAgentConcern

    default_schedule 'never'

    description <<-MD
      The `FremeNifConcerterAgent` allows to convert plain text, a document in any format supported by [e-Internalisation](http://api.freme-project.eu/doc/0.6/knowledge-base/freme-for-api-users/eInternationalisation.html) or in the RDF formats supported by FREME into a NIF document with the RDF serialisation format specified by the accept header.

      The Agent accepts all configuration options of the `/toolbox/nif-converter` endpoint as of version `0.6`, have a look at the [offical documentation](http://api.freme-project.eu/doc/0.6/api-doc/full.html#!/Toolbox/post_toolbox_nif_converter) if you need additional information.

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `base_url` allows to customize the API server when hosting the FREME services elswhere, make sure to include the API version.

      `outformat` requested RDF serialization format of the output

      `body_format` specify the content-type of the data in `body`

      `body` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the data to be send to the API.
    MD

    def default_options
      {
        'base_url' => 'http://api.freme-project.eu/0.6/',
        'outformat' => 'text/turtle',
        'body_format' => 'text/plain',
        'body' => '{{ body }}',
      }
    end

    form_configurable :base_url
    form_configurable :outformat, type: :array, values: ['text/n3', 'text/turtle', 'application/ld+json', 'application/n-triples', 'application/rdf+xml']
    form_configurable :body_format, type: :array, values: ['text/plain', 'text/xml', 'text/html', 'text/n3', 'text/turtle', 'application/ld+json', 'application/n-triples', 'application/rdf+xml', 'application/x-xliff+xml', 'application/x-openoffice']
    form_configurable :body, type: :text, ace: true

    def validate_options
      errors.add(:base, "body needs to be present") if options['body'].blank?
      errors.add(:base, "base_url needs to be present") if options['base_url'].blank?
      errors.add(:base, "base_url needs to end with a trailing '/'") unless options['base_url'].end_with?('/')
      errors.add(:base, "outformat needs to be present") if options['outformat'].blank?
      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)
        nif_request!(mo, ['outformat'], URI.join(mo['base_url'], 'toolbox/nif-converter'))
      end
    end
  end
end
