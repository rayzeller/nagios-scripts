#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'net/http'
require 'uri'
require 'optparse'
require 'timeout'


def parse_args(args)
  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = 'Usage: %s -i <store_id> -t <minutes>' % [$0]

    options[:service] = 5
    opts.on('-s', '--s [string]', :text, 'Twilio Service.') do |x|
      options[:service] = x
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
  if not (options[:service]) then
    error_msg.push('Must specify twilio service.')
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

string=`curl http://status.twilio.com/api/v1/services/#{options[:service]}/events`
value = JSON.parse(string)['events'][0]['status']
case value["level"]
 when "NORMAL"
  puts "OK - #{value['description']}"
  exit 0
 when "WARNING"
  puts "WARNING - #{value['description']}"
  exit 1
 else
  puts "CRITICAL - #{value['description']}"
  exit 2
end