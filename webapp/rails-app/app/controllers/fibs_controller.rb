class FibsController < ApplicationController
  def index
    start_time = Time.now()
    @num = params.fetch(:num, 10).to_i
    grpc = params.fetch(:grpc, false) != 'false'
    @computed = grpc ? fib_grpc(@num) : fib(@num)
    @elapsed = Time.now() - start_time
  end

  private
  def fib (num)
    num == 0 ? 0 : num == 1 ? 1 : fib(num - 1) + fib(num - 2)
  end

  def fib_grpc (num)
    require 'fib_services_pb'
    stub = Fib::Fib::Stub.new('localhost:50051', :this_channel_is_insecure)
    stub.fib(Fib::FibRequest.new(arg: num)).res
  end
end
