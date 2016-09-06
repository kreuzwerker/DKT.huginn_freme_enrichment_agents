require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::FremeLinkAgent do
  before(:each) do
    @valid_options = Agents::FremeLinkAgent.new.default_options.merge('templateid' => '1245')
    @checker = Agents::FremeLinkAgent.new(:name => "somename", :options => @valid_options)
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

    it "requires templateid to be set" do
      @checker.options['templateid'] = ''
      expect(@checker).not_to be_valid
    end
  end

  describe '#complete_templateid' do
    before(:each) do
      faraday_mock = mock()
      @response_mock = mock()
      mock(faraday_mock).run_request(:get, URI.parse('http://api.freme-project.eu/0.6/e-link/templates'), nil, { 'X-Auth-Token'=> nil, 'Accept' => 'application/json'}) { @response_mock }
      mock(@checker).faraday { faraday_mock }
    end
    it "returns the available datasets" do
      stub(@response_mock).status { 200 }
      stub(@response_mock).body { JSON.dump([ {'id' => '1245', 'label' => 'label', 'description' => 'description'} ]) }
      expect(@checker.complete_templateid).to eq([{text: "label", id: "1245", description: 'description'}])
    end

    it "returns an empty array if the request failed" do
      stub(@response_mock).status { 500 }
      expect(@checker.complete_templateid).to eq([])
    end
  end

  describe "#receive" do
    before(:each) do
      @event = Event.new(payload: {data:
                        <<-END
                        @prefix dc:    <http://purl.org/dc/elements/1.1/> .
                        @prefix prov:  <http://www.w3.org/ns/prov#> .
                        @prefix nif:   <http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#> .
                        @prefix itsrdf: <http://www.w3.org/2005/11/its/rdf#> .
                        @prefix rutp:  <http://rdfunit.aksw.org/data/patterns#> .
                        @prefix rlog:  <http://persistence.uni-leipzig.org/nlp2rdf/ontologies/rlog#> .
                        @prefix oslc:  <http://open-services.net/ns/core#> .
                        @prefix dsp:   <http://dublincore.org/dc-dsp#> .
                        @prefix dcterms: <http://purl.org/dc/terms/> .
                        @prefix rutg:  <http://rdfunit.aksw.org/data/generators#> .
                        @prefix schema: <http://schema.org/> .
                        @prefix olia:  <http://purl.org/olia/olia.owl#> .
                        @prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#> .
                        @prefix p:     <http://127.0.0.1:9995/spotlight#> .
                        @prefix rut:   <http://rdfunit.aksw.org/ns/core#> .
                        @prefix xsd:   <http://www.w3.org/2001/XMLSchema#> .
                        @prefix owl:   <http://www.w3.org/2002/07/owl#> .
                        @prefix rutr:  <http://rdfunit.aksw.org/data/results#> .
                        @prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                        @prefix spin:  <http://spinrdf.org/spin#> .
                        @prefix rutt:  <http://rdfunit.aksw.org/data/tests#> .
                        @prefix ruts:  <http://rdfunit.aksw.org/data/testsuite#> .

                        <http://127.0.0.1:9995/spotlight#char=0,15>
                        a                     nif:Context , nif:Sentence , nif:RFC5147String ;
                        nif:beginIndex        "0" ;
                        nif:endIndex          "15" ;
                        nif:isString          "This is Berlin." ;
                        nif:referenceContext  <http://127.0.0.1:9995/spotlight#char=0,15> .

                        <http://127.0.0.1:9995/spotlight#char=8,14>
                        a                     nif:Word , nif:RFC5147String ;
                        nif:anchorOf          "Berlin" ;
                        nif:beginIndex        "8" ;
                        nif:endIndex          "14" ;
                        nif:referenceContext  <http://127.0.0.1:9995/spotlight#char=0,15> ;
                        itsrdf:taIdentRef     <http://dbpedia.org/resource/Berlin> .
                        END
      })
    end

    it "creates an event after a successful request" do
      stub_request(:post, "http://api.freme-project.eu/0.6/e-link/documents?outformat=turtle&templateid=1245").
         with(:headers => {'X-Auth-Token'=> nil, 'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/turtle', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
         to_return(:status => 200, :body => "DATA", :headers => {})
      expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq('DATA')
    end

  end
end
