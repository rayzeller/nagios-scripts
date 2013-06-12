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

    options[:api_key] = 5
    opts.on('-k', '--k [string]', :text, 'API KEY') do |x|
      options[:api_key] = x
    end

    options[:api_secret] = 5
    opts.on('-s', '--s [string]', :text, 'API SECRET.') do |x|
      options[:api_secret] = x
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
  if not (options[:api_secret]) then
    error_msg.push('Must specify api secret.')
  end
  if not (options[:api_key]) then
    error_msg.push('Must specify api key.')
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
start = eval `date -v -60M "+%s"`
string=`curl https://api.phaxio.com/v1/faxList \
        -F 'start=#{start}' \
        -F 'api_key=#{options[:api_key]}' \
        -F 'api_secret=#{options[:api_secret]}'`

        # -F 'start=1293861600' \
        # -F 'end=1294034400' \

value = JSON.parse(string)
if(value['data'].nil?)
  puts "OK - No faxes in last hour"
  exit 0
end
case value["data"][0]['error_type']
when "fatalError"
  puts "CRITICAL - #{value["data"][0]['error_code']}"
  exit 2
when "generalError"
  puts "CRITICAL - #{value["data"][0]['error_code']}"
  exit 2
else
  puts "OK - Last fax sent with status #{value['data'][0]['status']}"
  exit 0
end