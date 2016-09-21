require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::FremeSpotlightAgent do
  before(:each) do
    @valid_options = Agents::FremeSpotlightAgent.new.default_options
    @checker = Agents::FremeSpotlightAgent.new(:name => "somename", :options => @valid_options)
    @checker.user = users(:jane)
    @checker.save!
  end

  it_behaves_like WebRequestConcern
  it_behaves_like FremeNifApiAgentConcern
  it_behaves_like FremeFilterable

  describe "validating" do
    before do
      expect(@checker).to be_valid
    end

    it "requires body to be present" do
      @checker.options['body'] = ''
      expect(@checker).not_to be_valid
    end

    it "requires base_url to be set" do
      @checker.options['base_url'] = ''
      expect(@checker).not_to be_valid
    end

    it "requires base_url to end with a slash" do
      @checker.options['base_url']= 'http://example.com'
      expect(@checker).not_to be_valid
    end

    it "requires numLinks to be empty or between 0 and 5" do
      %w{asdf 6 -1 0}.each do |invalid|
        @checker.options['numLinks'] = invalid
        expect(@checker).not_to be_valid
      end
    end
  end

  describe "#receive" do
    before(:each) do
      @event = Event.new(payload: {data: "Hello from Huginn"})
    end

    it "creates an event after a successful request" do
      stub_request(:post, "http://api.freme-project.eu/current/e-entity/dbpedia-spotlight/documents?confidence=0.3&language=en&numLinks=1&outformat=text/turtle").
        with(:headers => {'X-Auth-Token'=> nil, 'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/plain', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
        to_return(:status => 200, :body => "DATA", :headers => {})
      expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq('DATA')
    end
  end
end
