module FremeFilterable
  extend ActiveSupport::Concern

  module ClassMethods
    def filterable_field
      form_configurable :filter, roles: :completable
    end

    def filterable_description
      "`filter` allows to post-process the results using a pre-configured SPARQL filter. Check the [official documentation](http://api.freme-project.eu/doc/0.6/knowledge-base/freme-for-api-users/filtering.html) for details."
    end

    def filterable_outformat_description
      ", CSV is only supported when using a filter"
    end
  end

  def complete_filter
    response = faraday.run_request(:get, URI.join(interpolated['base_url'], 'toolbox/convert/manage'), nil, auth_header.merge({'Accept' => 'application/json'}))
    return [] if response.status != 200

    [text: 'none', id: ''] + JSON.parse(response.body).map { |filter| { text: "#{filter['name']}", id: filter['name'], description: filter['description'] } }
  end
end