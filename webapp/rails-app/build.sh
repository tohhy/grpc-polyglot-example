bundle exec grpc_tools_ruby_protoc -I ../proto --ruby_out=generated --grpc_out=generated ../proto/fib.proto
pushd ../rust && cargo build --release && popd
