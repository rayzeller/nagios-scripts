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
    opts.banner = 'Usage: %s -i <account_sid> -t <auth_token> -s <status> -w <warning_threshold> -c <critical_threshold> -p <page_size>' % [$0]
    options[:status] = 5
    opts.on('-s', '--s [string]', :text, 'Twilio Status to query for.') do |x|
      options[:status] = x
    end

    options[:token] = 5
    opts.on('-t', '--t [string]', :text, 'Twilio Account Auth Token.') do |x|
      options[:token] = x
    end

    options[:sid] = 5
    opts.on('-i', '--i [string]', :text, 'Twilio Account Sid.') do |x|
      options[:sid] = x
    end

    options[:warning] = 25
    opts.on('-w', '--w [INTEGER]', OptionParser::DecimalInteger, 'Warning Threshold.') do |x|
      options[:warning] = x
    end

    options[:critical] = 25
    opts.on('-c', '--c [INTEGER]', OptionParser::DecimalInteger, 'Critical Threshold.') do |x|
      options[:critical] = x
    end

    options[:page_size] = 100
    opts.on('-p', '--p [INTEGER]', OptionParser::DecimalInteger, 'Page Size') do |x|
      options[:page_size] = x
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
  if not (options[:sid]) then
    error_msg.push('Must specify twilio account sid.')
  end
  if not (options[:status]) then
    error_msg.push('Must specify twilio status.')
  end
  if not (options[:token]) then
    error_msg.push('Must specify twilio token.')
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
start_time=(Time.now-86400).strftime('%F')

string=`curl -G https://api.twilio.com/2010-04-01/Accounts/#{options[:sid]}/Calls.json \
    -u #{options[:sid]}:#{options[:token]} \
    -d Status=#{options[:status]} \
    -d pagesize=#{options[:page_size]} \
    -d StartTime=#{start_time}`
value = JSON.parse(string)
if(value["total"].to_i < options[:warning])
  puts "OK - #{value['total']} Twilio calls are in the call queue.  This is a normal number."
  exit 0
elsif(value["total"].to_i < options[:critical] && value["total"].to_i >= options[:warning])
  puts "WARNING - #{value['total']} Twilio calls are in the call queue.  Please keep an eye on calls."
  exit 1
else
  puts "CRITICAL - #{value['total']} Twilio calls are in the call queue.  Please notify an engineer immediately.  This is a lot of calls."
  exit 2
end