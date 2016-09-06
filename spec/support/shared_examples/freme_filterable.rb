require 'rails_helper'

shared_examples_for FremeFilterable do
  describe '#complete_filter' do
    before(:each) do
      faraday_mock = mock()
      @response_mock = mock()
      mock(faraday_mock).run_request(:get, URI.parse('http://api.freme-project.eu/0.6/toolbox/convert/manage'), nil, { 'X-Auth-Token'=> nil, 'Accept' => 'application/json'}) { @response_mock }
      mock(@checker).faraday { faraday_mock }
    end
    it "returns the available filters" do
      stub(@response_mock).status { 200 }
      stub(@response_mock).body { JSON.dump([ {'name' => 'testfilter', 'description' => nil} ]) }
      expect(@checker.complete_filter).to eq([{text: 'none', id: ''}, {text: "testfilter", id: "testfilter", description: nil}])
    end

    it "returns an empty array if the request failed" do
      stub(@response_mock).status { 500 }
      expect(@checker.complete_filter).to eq([])
    end
  end
end
