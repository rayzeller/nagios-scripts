#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'net/http'
require 'uri'
require 'optparse'
require 'timeout'
require 'date'


def parse_args(args)
  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = 'Usage: %s -k <api_key> -d <domain> -s <search string> (optional) -m <minutes_ago> -l <limit>' % [$0]

    options[:api_key] = 5
    opts.on('-k', '--k [string]', :text, 'API KEY') do |x|
      options[:api_key] = x
    end

    options[:domain] = 5
    opts.on('-d', '--d [string]', :text, 'DOMAIN.') do |x|
      options[:domain] = x
    end

    options[:search] = 5
    opts.on('-s', '--s [string]', :text, 'SEARCH STRING.') do |x|
      options[:search] = x
    end

    options[:minutes] = 3
    opts.on('-m', '--m [DECIMAL]', OptionParser::DecimalInteger, 'MINUTES.') do |x|
      options[:minutes] = x
    end
    options[:limit] = 1000
    opts.on('-l', '--l [DECIMAL]', OptionParser::DecimalInteger, 'LIMIT.') do |x|
      options[:limit] = x
    end
  end
  optparse.parse!(args)
  options
end

# Output one-liner and manage the exit code explicitly.
def do_exit (v, code, msg)
    puts msg unless msg == nil
    if v == true
        exit 3
    else
        exit code
    end
end

def sanity_check(options)
  # In life, some arguments cannot be avoided.
  error_msg = []
  if not (options[:api_key]) then
    error_msg.push('Must specify api secret.')
  end
  if not (options[:domain]) then
    error_msg.push('Must specify domain.')
  end

  if not (options[:search]) then
    error_msg.push('Must specify search string.')
  end
  
  if error_msg.length > 0 then
    # First line is Nagios-friendly.
    puts 'UNKNOWN: Insufficient or incompatible arguments.'
    # Subsequent lines are for humans.
    error_msg.each do |msg|
      puts msg
    end
    msg = '"%s ask ray for for info"' % [$0]
    do_exit(true, 3, msg)
  end
end

options = parse_args(ARGV)
sanity_check(options)
string=`curl -s --user api:#{options[:api_key]} \
    -G https://api.mailgun.net/v2/#{options[:domain]}/log \
    -d skip=0 \
    -d limit=#{options[:limit]}`

        # -F 'start=1293861600' \
        # -F 'end=1294034400' \

value = JSON.parse(string)
value['items'].each do |v|
  if(DateTime.parse(v['created_at']) > DateTime.now - options[:minutes].to_f/1440.0)
    case v['type']
      when "info"
        
      else
        if(v['message'].match(options[:search]))
          puts "CRITICAL - #{v['message']}"
          exit 2
        end
      end
  end
end
puts "OK - All messages sent in last #{options[:minutes]} were fine."
exit 0