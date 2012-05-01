require 'rack/si'
require 'rack/test'

describe Rack::SI do
  include Rack::Test::Methods

  def app
    Rack::SI.new lambda { |env| [200, {}, []] }, options
  end

  describe '#call' do
    context 'with default options' do
      let(:options) { {} }

      it 'returns control to the app' do
        get '/foo'
        last_response.should be_ok
      end

      it 'ignores missing parameters' do
        post '/bar'
        last_request.params.should == {}
      end

      it 'does not convert non-unit params' do
        post '/automobile_trips', {
          'destination' => '2,3',
          'distance' => 233
        }
        last_request.params.should ==({
          'destination' => '2,3',
          'distance' => '233'
        })
      end

      it 'converts any unit-ed params to base SI units' do
        post '/automobile_trips', {
          'destination' => '2,3',
          'distance' => '233 miles'
        }
        last_request.params['destination'].should == '2,3'
        last_request.params['distance'].to_f.should == 374977.152
      end

      it 'keeps the original params close by' do
        post '/automobile_trips', {
          'destination' => '2,3',
          'distance' => '233 miles'
        }
        last_request.env['si.original_params']['destination'].should == '2,3'
        last_request.env['si.original_params']['distance'].should == '233 miles'
      end

      it 'converts compound measurements' do
        pending
        #post '/automobile_trips', {
          #'fuel_efficiency' => '54 miles per gallon'
        #}
        #last_request.env['si.params']['fuel_efficiency'].to_f.should == 86904.576
      end

      it 'converts dates' do
        pending
      end
    end

    context 'with env option' do
      let(:options) { { :env => true } }

      it 'saves SI params to a separate ENV hash if desired' do
        post '/automobile_trips', {
          'destination' => '2,3',
          'distance' => '233 miles'
        }
        last_request.params.should == {
          'destination' => '2,3',
          'distance' => '233 miles'
        }
        last_request.env['si.params']['destination'].should be_nil
        last_request.env['si.params']['distance'].to_f.should == 374977.152
      end
    end

    context 'with custom env option' do
      let(:options) { { :env => 'my.hash' } }

      it 'saves SI params to a custom ENV hash if desired' do
        post '/automobile_trips', {
          'destination' => '2,3',
          'distance' => '233 miles'
        }
        last_request.params.should == {
          'destination' => '2,3',
          'distance' => '233 miles'
        }
        last_request.env['my.hash']['destination'].should be_nil
        last_request.env['my.hash']['distance'].to_f.should == 374977.152
      end
    end

    context 'with whitelist' do
      let(:options) { { :whitelist => %w{distance} } }

      it 'converts only whitelisted SI params' do
        post '/automobile_trips', {
          'destination' => '2,3',
          'distance' => '233 miles',
          'weight' => '2013 lbs'
        }
        last_request.params.should == {
          'destination' => '2,3',
          'distance' => '374977.152',
          'weight' => '2013 lbs'
        }
      end
    end

    context 'with blacklist' do
      let(:options) { { :blacklist => %w{distance} } }

      it 'does not convert blacklisted SI params' do
        post '/automobile_trips', {
          'destination' => '2,3',
          'distance' => '233 miles',
          'weight' => '2013 lbs'
        }
        last_request.params.should == {
          'destination' => '2,3',
          'distance' => '233 miles',
          'weight' => '913081.4408100001'
        }
      end
    end
  end

  describe '#herbalizable?' do
    let(:options) { {} }
    let(:si) { app }

    it 'returns true if param is whitelisted and not blacklisted' do
      si.stub!(:whitelisted?).and_return true
      si.stub!(:blacklisted?).and_return false
      si.herbalizable?('foo').should be_true
    end
    it 'returns false if param is not whitelisted' do
      si.stub!(:whitelisted?).and_return false
      si.herbalizable?('foo').should be_false
    end
    it 'returns false if param is blacklisted' do
      si.stub!(:whitelisted?).and_return true
      si.stub!(:blacklisted?).and_return true
      si.herbalizable?('foo').should be_false
    end
  end

  describe '#whitelisted?' do
    let(:options) { {} }
    let(:si) { app }

    it 'returns true if the whitelist is empty' do
      si.options[:whitelist] = []
      si.whitelisted?('foo').should be_true
    end
    it 'returns true if the param is in the whitelist' do
      si.options[:whitelist] = ['foo']
      si.whitelisted?('foo').should be_true
    end
    it 'returns false if the param is not in the whitelist' do
      si.options[:whitelist] = ['foo']
      si.whitelisted?('bar').should be_false
    end
  end

  describe '#blacklisted?' do
    let(:options) { {} }
    let(:si) { app }

    it 'returns false if the blacklist is empty' do
      si.options[:blacklist] = []
      si.blacklisted?('foo').should be_false
    end
    it 'returns true if the param is in the blacklist' do
      si.options[:blacklist] = ['foo']
      si.blacklisted?('foo').should be_true
    end
    it 'returns false if the param is not in the blacklist' do
      si.options[:blacklist] = ['foo']
      si.blacklisted?('bar').should be_false
    end
  end
end
