#!/usr/bin/env ruby

this_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(this_dir, 'generated')
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require 'grpc'
require 'fib_services_pb'

def main
  stub = Fib::Fib::Stub.new('localhost:50051', :this_channel_is_insecure)
  arg = ARGV.size > 0 ?  ARGV[0].to_i : 10
  num = stub.fib(Fib::FibRequest.new(arg: arg)).num
  p "Fib: #{num}"
end

main
