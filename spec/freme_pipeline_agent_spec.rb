require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::FremePipelineAgent do
  before(:each) do
    @valid_options = Agents::FremePipelineAgent.new.default_options
    @checker = Agents::FremePipelineAgent.new(:name => "somename", :options => @valid_options)
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
  end

  it "#complete_template_id returns a list of available templates" do
    stub_request(:get, "http://api.freme-project.eu/0.6/pipelining/templates").
      with(:headers => {'X-Auth-Token'=> nil, 'Accept'=>'application/json', 'Accept-Encoding'=>'gzip,deflate', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
      to_return(:status => 200, :body => '[{"id": 34,"description": "First e-Entity, then e-Translate"}]', :headers => {})
    expect(@checker.complete_template_id).to eq([{text: "First e-Entity, then e-Translate", id: 34}])
  end

  describe "#receive" do
    before(:each) do
      @event = Event.new(payload: {body: "Hello from Huginn"})
    end

    it "creates an event after a successfull request" do
      stub_request(:post, "http://api.freme-project.eu/0.6/pipelining/chain?stats=false").
        with(:body => "Hello from Huginn",
             :headers => {'X-Auth-Token'=> nil, 'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'application/json', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
        to_return(:status => 200, :body => "DATA", :headers => {})
      expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq('DATA')
    end

    it "uses the configured pipeline template" do
      stub_request(:post, "http://api.freme-project.eu/0.6/pipelining/chain/34?stats=false").
        with(:body => "Hello from Huginn",
             :headers => {'X-Auth-Token'=> nil, 'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/plain', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
        to_return(:status => 200, :body => "DATA", :headers => {})
       @checker.options['template_id'] = '34'
       @checker.options['body_format'] = 'text/plain'
       expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
       event = Event.last
       expect(event.payload['body']).to eq('DATA')
    end
  end
end
