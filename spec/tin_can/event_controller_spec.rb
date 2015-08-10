require 'spec_helper'
describe TinCan::EventController do

  it 'requires a JSON string and parses it' do
    expect{ described_class.new("string") }.to raise_error JSON::ParserError
    expect{ described_class.new('{"message":"ok"}') }.to_not raise_error JSON::ParserError
    expect( described_class.new('{"message":"ok"}').params ).to be == {message: 'ok'}
  end


end
