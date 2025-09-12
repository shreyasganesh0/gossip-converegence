import gleam/list
import gleam/int
import gleam/io
import gleam/dict.{type Dict}

import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor

import gleam/erlang/process

import topology
import utls

pub type GossipMessage {
    
    InitActorState(neb_actors: List(process.Subject(GossipMessage)))

    HearRumor(id: Int)

    PropogateRumor(id: Int)
}

pub type RumorMap {

    RumorMap(count_map: Dict(Int, Int))
}

pub type GossipState {

    GossipState(
        id: Int,
        rumor_map: RumorMap,
        neb_list: List(process.Subject(GossipMessage)),
    )
}

pub fn start(num_nodes: Int, topology: topology.Type) {

    let main_sub = process.new_subject()

    let sup_builder = supervisor.new(supervisor.OneForOne)

    let init_state = GossipState(
                        0,
                        RumorMap(dict.from_list([])),
                        neb_list: [],
                    )

    let #(builder, actors_list) = utls.start_actors(num_nodes, init_state, handle_gossip, sup_builder)

    supervisor.start(builder)

    topology.create_connections(actors_list, topology)
    |> list.each(fn (a) {

                    let topology.NodeMappings(parent_actor, neb_actors) = a

                    process.send(parent_actor, InitActorState(neb_actors))
                }
       )

    process.receive_forever(main_sub)

}

fn handle_gossip(
   state: GossipState, 
   msg: GossipMessage
   ) -> actor.Next(GossipState, GossipMessage) {
    
    
    case msg {

        InitActorState(neb_actors) -> {

            let new_state = GossipState(
                                ..state,
                                neb_list: neb_actors
                            )
            echo neb_actors
            actor.continue(new_state)
        }

        PropogateRumor(rumor_id) -> {

            list.each(state.neb_list, fn(neb_sub) {

                                      process.send(neb_sub, HearRumor(1))
                                  }
            )
            actor.continue(state)
        }

        HearRumor(id) -> {
            io.println("got rumor " <> int.to_string(id))
            actor.continue(state)
        }
    }
}
