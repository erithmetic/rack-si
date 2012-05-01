# Rack::SI

Convert parameters into SI (metric) base units.

We all know the metric system is far superior to the imperial/customary system (except when performing mental math on lengths and volumes) so now there is a Rack middleware that will normalize all of your measurement input into SI!

# Installation

    $ gem install rack-si


    # config.ru
    require 'rack/si'
    
    use Rack::SI, options
    run MyApp

# Configuration

Rack::SI accepts several configuration options:

* *env*: If true, the converted params will appear in the env['si.params'] hash. If set to a string, the converted params will appear in the env[custom\_string] hash.
* *basic*: If true, and dkastner-herbalist is installed, keep Herbalist from matching spelled-out numbers and fractions. This helps performance.
* *path*: A single path or array of paths defined as strings and/or regexes. If set, params are translated only for specified paths.
* *whitelist*: A list of params that should be converted. All others are ignored. If left blank, all params are converted (unless blacklisted).
* *blacklist*: A list of params that should *not* be converted. All others are converted (if whitelisted). If left blank, all params are converted.
