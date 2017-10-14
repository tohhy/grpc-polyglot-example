#!/usr/bin/env ruby

def fib (num)
  num == 0 ? 0 : num == 1 ? 1 : fib(num - 1) + fib(num - 2)
end

def main
  arg = ARGV.size > 0 ?  ARGV[0].to_i : 10
  p "Fib: #{fib(arg)}"
end

main
