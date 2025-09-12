
import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor

import gleam/erlang/process

import topology
import utls

pub type PushSumMessage {

    SumWeight(s: Int, w: Int)
}

pub type PushSumState {
    
    PushSumStateTmp

    PushSumState(
        x: Int,
        w: Int,
    )
}
pub fn start(num_nodes: Int, topology: topology.Type) {

    let main_sub = process.new_subject()

    let sup_builder = supervisor.new(supervisor.OneForOne)

    let init_state = PushSumStateTmp
    let #(builder, actors_list) = utls.start_actors(num_nodes, init_state, handle_pushsum, sup_builder)

    supervisor.start(builder)

    process.receive_forever(main_sub)

    let _nodes_list = topology.create_connections(actors_list, topology)
}

fn handle_pushsum(
    state: PushSumState,
    msg: PushSumMessage,
    ) -> actor.Next(PushSumState, PushSumMessage) {

todo
}
