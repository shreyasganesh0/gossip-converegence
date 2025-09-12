import gleam/io
import gleam/int
import gleam/list

import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor

import gleam/erlang/process

import topology
import utls

pub type PushSumMessage {

    InitActorState(neb_actors: List(process.Subject(PushSumMessage)))

    SumWeight(s: Int, w: Int)
}

pub type PushSumState {
    
    PushSumState(
        x: Int,
        w: Int,
        neb_list: List(process.Subject(PushSumMessage)),
    )
}
pub fn start(num_nodes: Int, topology: topology.Type) {

    let main_sub = process.new_subject()

    let sup_builder = supervisor.new(supervisor.OneForOne)

    let init_state = PushSumState(
                        0,
                        0,
                        neb_list: [],
                    )


    let #(builder, nodes_list) = topology.create_connections(
        num_nodes,
        init_state,
        handle_pushsum,
        sup_builder,
        topology,
    )

    supervisor.start(builder)
    list.each(nodes_list, fn (a) {

                    let topology.NodeMappings(parent_actor, neb_actors) = a

                    process.send(parent_actor, InitActorState(neb_actors))
                }
    )

    process.receive_forever(main_sub)
}

fn handle_pushsum(
    state: PushSumState,
    msg: PushSumMessage,
    ) -> actor.Next(PushSumState, PushSumMessage) {

    case msg {

        InitActorState(neb_actors) -> {

            let new_state = PushSumState(
                ..state,
                neb_list: neb_actors,
            )

            actor.continue(new_state)
        }

        SumWeight(s, w) -> {

            io.println("[PUSHSUM_ACTOR]: received s: " <> int.to_string(s) <> " ,w: " <> int.to_string(w))
            actor.continue(state)
        }

    }
}
