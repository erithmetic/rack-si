require 'herbalist'

module Rack

  # A Rack middleware for converting params to base SI units
  #
  class SI
    attr_accessor :app, :options

    # These are the base SI units to which measurement params will be converted
    BASE_UNITS = [:metre, :metres, :meter, :meters, :litre, :litres, :liter, :liters, :joule, :joules, :gram, :grams, :watt, :watts]

    DEFAULT_OPTIONS = {
      :env => false,
      :basic => false,
      :whitelist => [],
      :blacklist => [],
      :path => []
    }

    # use Rack::SI my_options
    def initialize(app, options = {})
      self.app = app
      self.options = DEFAULT_OPTIONS.merge(options)

      normalize_options
      Herbalist.basic = true if Herbalist.respond_to?(:basic) && options[:basic]
    end

    # Make sure options are in the right format
    def normalize_options
      self.options[:whitelist] = self.options[:whitelist].map(&:to_s)
      self.options[:blacklist] = self.options[:blacklist].map(&:to_s)
      self.options[:path] = [self.options[:path]] unless self.options[:path].is_a?(Array)
    end

    # Called on each request
    def call(env, options = {})
      req = Request.new(env)
      convert_params(env, req) if path_matches?(req)
      app.call(env)
    end

    def path_matches?(req)
      options[:path].empty? || options[:path].find do |path|
        (path.is_a?(String) && req.path == path) ||
          (path.is_a?(Regexp) && req.path =~ path)
      end
    end

    def convert_params(env, req)
      if options[:env]
        convert_params_in_hash(env, req)
      else
        convert_params_in_situ(env, req)
      end
    end

    # Convert parameters, but put them in a special hash and
    # leave the regular Rack ENV params alone.
    # You can specify the name of the env[] key that stores
    # the params by configuring the app with the :env option
    def convert_params_in_hash(env, req)
      params = req.params
      hash_name = options[:env].is_a?(String) ? options[:env] : 'si.params'
      env[hash_name] = params.inject({}) do |hsh, (name, value)|
        herbalize(hsh, name, value)
      end
    end

    # Convert parameters "in place" - that is, modify all the 
    # params in env so that every other middleware sees 
    # the changes
    def convert_params_in_situ(env, req)
      env['si.original_params'] = req.params.dup
      [:GET, :POST].each do |method|
        hsh = req.send(method)
        hsh.each do |name, value|
          herbalize(hsh, name, value)
        end
      end
    end

    # Convert a parameter with Herbalist
    def herbalize(hsh, name, value)
      if herbalizable?(name) && measurement = Herbalist.parse(value)
        hsh[name] = normalize(measurement)
      end
      hsh
    end

    # Decides if a param should be converted with Herbalist
    def herbalizable?(param)
      whitelisted?(param) && !blacklisted?(param)
    end

    def whitelisted?(param)
      options[:whitelist].empty? || options[:whitelist].include?(param)
    end

    def blacklisted?(param)
      !options[:blacklist].empty? && options[:blacklist].include?(param)
    end

    # Convert a param to a base unit using Alchemist's 
    # conversion table
    def normalize(measurement)
      group_name = Alchemist.conversion_table.keys.find do |k|
        Alchemist.conversion_table[k].include?(measurement.unit_name)
      end
      group = Alchemist.conversion_table[group_name]
      base_unit = BASE_UNITS.find { |u| group.include?(u) }
      measurement.to.send(base_unit).to_s
    end
  end
end
