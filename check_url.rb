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
    opts.banner = 'Usage: %s -H <url> -s <search string>' % [$0]

    options[:url] = ''
    opts.on('-H', '--H [string]', :text, 'URL') do |x|
      options[:url] = x
    end

    options[:query] = ''
    opts.on('-s', '--s [string]', :text, 'Search String.') do |x|
      options[:query] = x
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
  if not (options[:url]) then
    error_msg.push('Must specify url.')
  end
  if not (options[:query]) then
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

result =`curl #{options[:url]}`
search = !result.match(options[:query]).nil?
case search
 when true
  puts "OK - #{options[:query]} was found."
  exit 0
 else
  puts "CRITICAL - #{options[:query]} ain't there!"
  exit 2
end