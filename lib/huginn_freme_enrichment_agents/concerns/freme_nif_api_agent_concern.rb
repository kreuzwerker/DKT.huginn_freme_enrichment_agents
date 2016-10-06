module FremeNifApiAgentConcern
  extend ActiveSupport::Concern

  included do
    can_dry_run!

    event_description <<-MD
      Events look like this:

          {
            "status": 200,
            "headers": {
              "Content-Type": "text/html",
              ...
            },
            "body": "<html>Some data...</html>"
          }
    MD
  end

  def working?
    received_event_without_error?
  end

  def check
    receive([Event.new])
  end

  module ClassMethods
    def common_nif_agent_fields
      form_configurable :merge, type: :boolean
      form_configurable :result_key
    end

    def common_nif_agent_fields_description
      Utils.unindent <<-MD
        `merge` set to `true` to retain the received payload and update it with the extracted result

        `result_key` when present the emitted Event data will be nested inside the specified key
      MD
    end

    def freme_auth_token_description
      "`auth_token` can be set to access private filters, datasets, templates or pipelines (depending on the agent)."
    end
  end

  private

  def auth_header(mo = nil)
    { 'X-Auth-Token' => (mo || interpolated)['auth_token'] }
  end

  def nif_request!(mo, configuration_keys, url, options = {})
    headers = auth_header(mo).merge({
      'Content-Type' => mo['body_format']
    })

    configuration_keys << 'filter' if defined?(FremeFilterable) && self.class.include?(FremeFilterable)

    params = {}
    configuration_keys.each do |param|
      params[param.gsub('_', '-')] = mo[param] if mo[param].present?
    end

    response = faraday.run_request(:post, url, mo['body'], headers) do |request|
      request.params.update(params)
    end

    create_nif_event!(mo, options[:event], body: response.body, headers: response.headers, status: response.status)
  end

  def create_nif_event!(mo, event, payload)
    original_payload = boolify(mo['merge']) ? event.payload : {}
    payload = {mo['result_key'] => payload} if mo['result_key'].present?

    create_event payload: original_payload.merge(payload)
  end
end
