require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::FremeExploreAgent do
  before(:each) do
    @valid_options = Agents::FremeExploreAgent.new.default_options.merge('endpoint' => 'http://endpoint.com', 'resource' => 'http://resource.com')
    @checker = Agents::FremeExploreAgent.new(:name => "somename", :options => @valid_options)
    @checker.user = users(:jane)
    @checker.save!
  end

  it_behaves_like WebRequestConcern
  it_behaves_like NifApiAgentConcern
  it_behaves_like FremeFilterable

  describe "validating" do
    before do
      expect(@checker).to be_valid
    end

    it "requires base_url to be set" do
      @checker.options['base_url'] = ''
      expect(@checker).not_to be_valid
    end

    it "requires base_url to end with a slash" do
      @checker.options['base_url']= 'http://example.com'
      expect(@checker).not_to be_valid
    end

    it "requires endpoint to be set" do
      @checker.options['endpoint'] = ''
      expect(@checker).not_to be_valid
    end

    it "requires resource to be set" do
      @checker.options['resource'] = ''
      expect(@checker).not_to be_valid
    end
  end

  describe "#receive" do
    before(:each) do
      @event = Event.new(payload: {data: "Hello from Huginn"})
    end

    it "set optional parameters when specified" do
      @checker.options['prefix'] = 'http://huginn.io'
      stub_request(:post, "http://api.freme-project.eu/0.6/e-link/explore?endpoint=http://endpoint.com&endpoint-type=sparql&outformat=turtle&resource=http://resource.com").
        with(:headers => {'X-Auth-Token'=> nil, 'Accept-Encoding'=>'gzip,deflate', 'Content-Length'=>'0', 'Content-Type'=>'', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
        to_return(:status => 200, :body => "DATA", :headers => {})
      expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
    end
  end
end
