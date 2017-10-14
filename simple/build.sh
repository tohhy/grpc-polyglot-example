bundle exec grpc_tools_ruby_protoc -I proto --ruby_out=ruby/generated --grpc_out=ruby/generated proto/fib.proto
pushd rust && cargo build --release && popd
