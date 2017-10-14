extern crate grpc;
extern crate grpc_polyglot_example;

use std::thread;
use grpc_polyglot_example::generated::fib_grpc::*;
use grpc_polyglot_example::generated::fib::*;

struct FibImpl;

impl Fib for FibImpl {
    fn fib(&self, _m: grpc::RequestOptions, req: FibRequest) -> grpc::SingleResponse<FibReply> {
        let mut r = FibReply::new();
        let arg = req.get_arg();
        let res = fib_rec(arg);
        println!("fib: {}", res);
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
