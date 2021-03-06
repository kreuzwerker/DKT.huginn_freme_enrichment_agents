module Agents
  class FremePipelineAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include FremeNifApiAgentConcern

    default_schedule 'never'

    description <<-MD
      The `FremePipelineAgent` allows to send a pipeline request to the FREME API.

      The Agent accepts all configuration options of the `/pipelining/chain` endpoint as of September 2016, have a look at the [offical documentation](http://api.freme-project.eu/doc/current/api-doc/full.html#!/pipelining/post_pipelining_chain) if you need additional information.

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `base_url` allows to customize the API server when hosting the FREME services elswhere.

      #{freme_auth_token_description}

      `template` When selecting a [pipeline-template](http://api.freme-project.eu/doc/current/api-doc/full.html#!/pipelining/get_pipelining_templates), `body` will be used as the input for the pipeline chain.

      `body_format` specify the content-type of the data in `body` (only used when a template is selected)

      `body` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the data to be send to the API.

      `stats` If true, adds timing statistics to the response: total duration of the pipeline and duration of each service called in the pipeline (in milliseconds).

      `useI18n` If `false`, enforces to not use [e-Internalization](https://freme-project.github.io//knowledge-base/freme-for-api-users/eInternationalisation.html), even if Content-Type header is one of the possible e-Internalization formats. For any othe value, e-Internalization will be used, if possible.

      #{common_nif_agent_fields_description}
    MD

    def default_options
      {
        'base_url' => 'http://api.freme-project.eu/current/',
        'body' => '{{ body }}',
        'stats' => 'false',
        'useI18n' => 'true'
      }
    end

    form_configurable :base_url
    form_configurable :auth_token
    form_configurable :template_id, roles: :completable
    form_configurable :body_format, type: :array, values: ['text/plain', 'text/n3', 'text/turtle', 'application/json', 'application/ld+json', 'application/n-triples', 'application/rdf+xml']
    form_configurable :body, type: :text, ace: true
    form_configurable :stats, type: :boolean
    form_configurable :useI18n, type: :boolean
    common_nif_agent_fields

    def validate_options
      errors.add(:base, "body needs to be present") if options['body'].blank?
      errors.add(:base, "base_url needs to be present") if options['base_url'].blank?
      errors.add(:base, "base_url needs to end with a trailing '/'") unless options['base_url'].end_with?('/')
      validate_web_request_options!
    end

    def complete_template_id
      response = faraday.run_request(:get, URI.join(interpolated['base_url'], 'pipelining/templates'), nil, auth_header.merge({ 'Accept' => 'application/json'}))
      return [] if response.status != 200

      JSON.parse(response.body).map { |template| { text: template['description'], id: template['id'] } }
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)
        if mo['template_id'].present?
          nif_request!(mo, ['stats', 'useI18n'], URI.join(mo['base_url'], "pipelining/chain/#{mo['template_id']}"), event: event)
        else
          mo['body_format'] = 'application/json'
          nif_request!(mo, ['stats', 'useI18n'], URI.join(mo['base_url'], 'pipelining/chain'), event: event)
        end
      end
    end
  end
end
