#!/usr/bin/env bash
#
# 上から順番に実行するだけでRust/Rails構成のサンプルアプリができあがるシェルスクリプト
# 事前にcargoとrails5をインストールしておいてください
# https://www.rustup.rs/
# http://guides.rubyonrails.org/getting_started.html
#

#
# RustとRailsのセットアップ
#
# curl https://sh.rustup.rs -sSf | sh
# gem install rails

#
# protoファイルを書く
#
mkdir proto

cat << EOS > proto/fib.proto
syntax = "proto3";

package fib;

service Fib {
  rpc Fib (FibRequest) returns (FibReply) {}
}

message FibRequest {
    int64 arg = 1;
}

message FibReply {
    int64 res = 1;
}

EOS


#
# Rustプロジェクトのセットアップ
#
mkdir -p  rust/src/generated

cat << EOS > rust/Cargo.toml
[package]
name = "grpc_polyglot_example"
version = "0.0.1"
authors = ["tohhy"]

[dependencies]
protobuf         = "1.*"
tls-api          = "0.*"
grpc             = "0.2.*"

[build-dependencies]
protoc-rust-grpc = "0.2.*"

EOS

cat << EOS > rust/build.rs
extern crate protoc_rust_grpc;

fn main() {
    protoc_rust_grpc::run(protoc_rust_grpc::Args {
        out_dir: "src/generated",
        includes: &["../proto"],
        input: &["../proto/fib.proto"],
        rust_protobuf: true,
    }).expect("protoc-rust-grpc");
}

EOS

cat << EOS > rust/src/lib.rs
extern crate protobuf;
extern crate grpc;
extern crate tls_api;
pub mod generated;

EOS

cat << EOS > rust/src/generated/mod.rs
pub mod fib;
pub mod fib_grpc;

EOS

pushd rust && cargo build && popd


#
# Rust実装
#
cat << EOS > rust/src/fib_server.rs
extern crate grpc;
extern crate grpc_polyglot_example;

use std::thread;
use grpc_polyglot_example::generated::fib_grpc::*;
use grpc_polyglot_example::generated::fib::*;

struct FibImpl;

impl Fib for FibImpl {
    fn fib(&self, _m: grpc::RequestOptions, req: FibRequest)
            -> grpc::SingleResponse<FibReply> {
        let mut r = FibReply::new();
        let arg = req.get_arg();
        let res = fib_rec(arg);
        println!("fib({}): {}", arg, res);
        r.set_res(res);
        grpc::SingleResponse::completed(r)
    }
}

fn fib_rec (num: i64) -> i64 {
    if num == 0 {
        0
    } else if num == 1 {
        1
    } else {
        fib_rec(num - 1) + fib_rec(num - 2)
    }
}

fn main() {
    let mut server = grpc::ServerBuilder::new_plain();
    server.http.set_port(50051);
    server.add_service(FibServer::new_service_def(FibImpl));
    server.http.set_cpu_pool_threads(4);
    let _server = server.build().expect("server");

    loop {
        thread::park();
    }
}

EOS

cat << EOS >> rust/Cargo.toml
[[bin]]
name = "fib_server"
path = "src/fib_server.rs"
test = false

EOS

pushd rust && cargo build --release && popd


#
# Rails
#

# rails new
rails new rails-app
cd rails-app

# グルーコード生成
echo "gem 'grpc-tools'" >> Gemfile
echo "gem 'grpc'" >> Gemfile
bundle install
mkdir generated
bundle exec grpc_tools_ruby_protoc \
-I ../proto --ruby_out=generated --grpc_out=generated ../proto/fib.proto

# 依存関係読み込み
cat << EOS > config/application.rb
require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)

module RailsApp
  class Application < Rails::Application
    config.load_defaults 5.1
    config.autoload_paths << Rails.root.join("generated")
  end
end

EOS

# コントローラ実装
cat << EOS > app/controllers/fibs_controller.rb
class FibsController < ApplicationController
  def index
    start_time = Time.now()
    @num = params.fetch(:num, 10).to_i
    @grpc = params.fetch(:grpc, 'false') != 'false'
    @computed = @grpc ? fib_grpc(@num) : fib(@num)
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

EOS

cat << EOS > config/routes.rb
Rails.application.routes.draw do
  root :to => 'fibs#index'
end

EOS

# ビュー実装
mkdir -p app/views/fibs

cat << EOS > app/views/fibs/index.html.erb
<h1>Fibs(by <%= @grpc ? 'rust' : 'ruby' %>)</h1>

<p>Fib(<%= @num %>) : <%= @computed %></p>
<p>elapsed : <%= @elapsed %>(s)</p>

EOS


# サーバ起動処理を実装
cat << EOS > config.ru
require_relative 'config/environment'

# launch fib_server
Thread.new {
  system '../rust/target/release/fib_server'
}

run Rails.application

EOS

rails s

# open http://0.0.0.0:3000/?num=40&grpc=true
