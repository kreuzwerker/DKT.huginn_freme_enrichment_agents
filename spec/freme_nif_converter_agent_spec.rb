require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::FremeNifConverterAgent do
  before(:each) do
    @valid_options = Agents::FremeNifConverterAgent.new.default_options
    @checker = Agents::FremeNifConverterAgent.new(:name => "somename", :options => @valid_options)
    @checker.user = users(:jane)
    @checker.save!
  end

  it_behaves_like WebRequestConcern
  it_behaves_like FremeNifApiAgentConcern

  describe "validating" do
    before do
      expect(@checker).to be_valid
    end

    it "requires body to be present" do
      @checker.options['body'] = ''
      expect(@checker).not_to be_valid
    end

    it "requires outformat to be present" do
      @checker.options['outformat'] = ''
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

  describe "#receive" do
    before(:each) do
      @event = Event.new(payload: {body: "Hello from Huginn"})
    end

    it "creates an event after a successfull request" do
      stub_request(:post, "http://api.freme-project.eu/current/toolbox/nif-converter?outformat=text/turtle").
        with(:body => "Hello from Huginn",
             :headers => {'X-Auth-Token'=> nil, 'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/plain', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
        to_return(:status => 200, :body => "DATA", :headers => {})
      expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq('DATA')
    end

    context 'handling incoming file pointers' do
      let(:event) { Event.new(payload: {file_pointer: {agent_id: 111, file: 'test'}}) }

      before do
        stub_request(:post, "http://api.freme-project.eu/current/toolbox/nif-converter").
          with(:body => "-------------RubyMultipartPost\r\nContent-Disposition: form-data; name=\"inputFile\"; filename=\"local.path\"\r\nContent-Length: 8\r\nContent-Type: \r\nContent-Transfer-Encoding: binary\r\n\r\ntestdata\r\n-------------RubyMultipartPost\r\nContent-Disposition: form-data; name=\"informat\"\r\n\r\nTIKAFile\r\n-------------RubyMultipartPost\r\nContent-Disposition: form-data; name=\"outformat\"\r\n\r\ntext/turtle\r\n-------------RubyMultipartPost--\r\n\r\n",
               :headers => {'Accept-Encoding'=>'gzip,deflate', 'Content-Length'=>'413', 'Content-Type'=>'multipart/form-data; boundary=-----------RubyMultipartPost', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
          to_return(:status => 200, :body => "DATA", :headers => {})

        io_mock = mock()
        mock(@checker).get_io(event) { StringIO.new("testdata") }
      end

      it 'does not merge per default' do
        expect { @checker.receive([event]) }.to change(Event, :count).by(1)
        event = Event.last
        expect(event.payload['body']).to eq('DATA')
        expect(event.payload[:file_pointer]).to be_nil
      end

      it 'merges the results with the received event when merge is set to true' do
        @checker.options['merge'] = "true"
        expect { @checker.receive([event]) }.to change(Event, :count).by(1)
        event = Event.last
        expect(event.payload[:file_pointer]).to eq({'agent_id' => 111, 'file' => 'test'})
      end
    end
  end
end
