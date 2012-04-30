require 'herbalist'
Herbalist.basic = true

module Rack

  # A Rack middleware for converting params to base SI units
  #
  class Rack::SI
    BASE_UNITS = [:metre, :metres, :meter, :meters, :litre, :litres, :liter, :liters, :joule, :joules, :gram, :grams, :watt, :watts]

    def initialize(app)
      @app = app
    end

    def call(env)
      convert_params(env)
      @app.call(env)
    end

    def convert_params(env)
      params = ::Rack::Request.new(env).params
      env['si.params'] = params.inject({}) do |hsh, (name, value)|
        if measurement = Herbalist.parse(value)
          value = normalize(measurement)
        end
        hsh[name] = value
        hsh
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
