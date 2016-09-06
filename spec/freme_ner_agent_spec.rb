require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::FremeNerAgent do
  before(:each) do
    @valid_options = Agents::FremeNerAgent.new.default_options.merge('dataset' => 'testset')
    @checker = Agents::FremeNerAgent.new(:name => "somename", :options => @valid_options)
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

    it "requires dataset to be set" do
      @checker.options['dataset'] = ''
      expect(@checker).not_to be_valid
    end

    it "requires numLinks to be empty or between 0 and 5" do
      %w{asdf 6 -1 0}.each do |invalid|
        @checker.options['numLinks'] = invalid
        expect(@checker).not_to be_valid
      end
    end
  end

  describe '#complete_dataset' do
    before(:each) do
      faraday_mock = mock()
      @response_mock = mock()
      mock(faraday_mock).run_request(:get, URI.parse('http://api.freme-project.eu/0.6/e-entity/freme-ner/datasets'), nil, { 'X-Auth-Token'=> nil, 'Accept' => 'application/json'}) { @response_mock }
      mock(@checker).faraday { faraday_mock }
    end
    it "returns the available datasets" do
      stub(@response_mock).status { 200 }
      stub(@response_mock).body { JSON.dump([ {'name' => 'setname', 'description' => 'setdescription', 'id' => 'testset'} ]) }
      expect(@checker.complete_dataset).to eq([{:text=>"setname: setdescription", :id=>"setname"}])
    end

    it "returns an empty array if the request failed" do
      stub(@response_mock).status { 500 }
      expect(@checker.complete_dataset).to eq([])
    end
  end

  describe "#receive" do
    before(:each) do
      @event = Event.new(payload: {data: "Hello from Huginn"})
    end

    it "creates an event after a successful request" do
      stub_request(:post, "http://api.freme-project.eu/0.6/e-entity/freme-ner/documents?dataset=testset&language=en&mode=all&numLinks=1&outformat=turtle").
         with(:body => "Hello from Huginn",
              :headers => {'X-Auth-Token'=> nil, 'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/plain', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
         to_return(:status => 200, :body => "DATA", :headers => {})
      expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq('DATA')
    end

    it "set optional parameters when specified" do
      @checker.options['prefix'] = 'http://huginn.io'
      stub_request(:post, "http://api.freme-project.eu/0.6/e-entity/freme-ner/documents?dataset=testset&language=en&mode=all&numLinks=1&outformat=turtle&prefix=http://huginn.io").
         with(:body => "Hello from Huginn",
              :headers => {'X-Auth-Token'=> nil, 'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/plain', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
         to_return(:status => 200, :body => "DATA", :headers => {})
      expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
    end
  end
end
