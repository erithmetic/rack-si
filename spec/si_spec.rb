require 'rack/si'
require 'rack/test'

describe Rack::SI do
  include Rack::Test::Methods

  def app
    Rack::SI.new lambda { |env| [200, {}, []] }
  end

  describe '#call' do
    it 'returns control to the app' do
      get '/foo'
      last_response.should be_ok
    end

    it 'ignores missing parameters' do
      post '/bar'
      last_request.env['si.params'].should == {}
    end

    it 'does not convert non-unit params' do
      post '/automobile_trips', {
        'destination' => '2,3',
        'distance' => 233
      }
      last_request.env['si.params'].should ==({
        'destination' => '2,3',
        'distance' => '233'
      })
    end

    it 'converts any unit-ed params to base SI units' do
      post '/automobile_trips', {
        'destination' => '2,3',
        'distance' => '233 miles'
      }
      last_request.env['si.params']['destination'].should == '2,3'
      last_request.env['si.params']['distance'].to_f.should == 374977.152
    end

    #it 'converts compound measurements' do
      #post '/automobile_trips', {
        #'fuel_efficiency' => '54 miles per gallon'
      #}
      #last_request.env['si.params']['fuel_efficiency'].to_f.should == 86904.576
    #end

    #it 'converts dates' do

    #end
  end
end

