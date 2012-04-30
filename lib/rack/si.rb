require 'herbalist'

module Rack

  # A Rack middleware for converting params to base SI units
  #
  class Rack::SI
    attr_accessor :app, :options

    BASE_UNITS = [:metre, :metres, :meter, :meters, :litre, :litres, :liter, :liters, :joule, :joules, :gram, :grams, :watt, :watts]

    def initialize(app, options = {})
      self.app = app
      self.options = options
      Herbalist.basic = true if Herbalist.respond_to?(:basic) && options[:basic]
    end

    def call(env, options = {})
      convert_params(env)
      app.call(env)
    end

    def convert_params(env)
      if options[:env]
        convert_params_in_hash(env)
      else
        convert_params_in_situ(env)
      end
    end

    def convert_params_in_hash(env)
      params = Request.new(env).params
      hash_name = options[:env].is_a?(String) ? options[:env] : 'si.params'
      env[hash_name] = params.inject({}) do |hsh, (name, value)|
        if measurement = Herbalist.parse(value)
          hsh[name] = normalize(measurement)
        end
        hsh
      end
    end

    def convert_params_in_situ(env)
      req = Request.new(env)
      env['si.original_params'] = req.params.dup
      [:GET, :POST].each do |method|
        req.send(method).each do |name, value|
          if measurement = Herbalist.parse(value)
            req.send(method)[name] = normalize(measurement)
          end
        end
      end
    end

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
