# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

# launch fib_server
Thread.new {
  system '../rust/target/release/fib_server'
}

run Rails.application
