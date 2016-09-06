require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::FremeFilterAgent do
  before(:each) do
    @valid_options = Agents::FremeFilterAgent.new.default_options.merge('name' => 'testfilter')
    @checker = Agents::FremeFilterAgent.new(:name => "somename", :options => @valid_options)
    @checker.user = users(:jane)
    @checker.save!
  end

  it_behaves_like WebRequestConcern
  it_behaves_like NifApiAgentConcern

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

    it "requires name to be set" do
      @checker.options['name'] = ''
      expect(@checker).not_to be_valid
    end
  end

  describe '#complete_name' do
    before(:each) do
      faraday_mock = mock()
      @response_mock = mock()
      mock(faraday_mock).run_request(:get, URI.parse('http://api.freme-project.eu/0.6/toolbox/convert/manage'), nil, { 'X-Auth-Token'=> nil, 'Accept' => 'application/json'}) { @response_mock }
      mock(@checker).faraday { faraday_mock }
    end
    it "returns the available filters" do
      stub(@response_mock).status { 200 }
      stub(@response_mock).body { JSON.dump([ {'name' => 'testfilter', 'description' => nil} ]) }
      expect(@checker.complete_name).to eq([{text: "testfilter", id: "testfilter", description: nil}])
    end

    it "returns an empty array if the request failed" do
      stub(@response_mock).status { 500 }
      expect(@checker.complete_name).to eq([])
    end
  end

  describe "#receive" do
    before(:each) do
      @event = Event.new(payload: {data:
         <<-END
          @prefix xsd:   <http://www.w3.org/2001/XMLSchema#> .
          @prefix nif:   <http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#> .

          <http://freme-project.eu/#char=0,17>
                  a               nif:RFC5147String , nif:Context , nif:String ;
                  nif:beginIndex  "0"^^xsd:nonNegativeInteger ;
                  nif:endIndex    "17"^^xsd:nonNegativeInteger ;
                  nif:isString    "Hello from Huginn" .
         END
      })
    end

    it "creates an event after a successful request" do
      stub_request(:post, "http://api.freme-project.eu/0.6/toolbox/convert/documents/testfilter?outformat=turtle").
        with(:headers => {'X-Auth-Token'=> nil, 'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/turtle', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
        to_return(:status => 200, :body => "DATA", :headers => {})
      expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq('DATA')
    end

  end
end
