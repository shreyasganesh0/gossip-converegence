import gleam/list
import gleam/int
import gleam/io
import gleam/option.{Some, None}
import gleam/dict.{type Dict}

import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor

import gleam/erlang/process

import topology

pub type GossipMessage {
    
    InitActorState(neb_actors: List(process.Subject(GossipMessage)), id: Int)

    HearRumor(id: Int)
}


pub type GossipState {

    GossipState(
        id: Int,
        max_rumors: Int, 
        main_sub: process.Subject(Nil),
        rumor_map: Dict(Int, Int),
        neb_list: List(process.Subject(GossipMessage)),
    )
}

pub fn start(num_nodes: Int, topology: topology.Type) {

    let main_sub = process.new_subject()

    let sup_builder = supervisor.new(supervisor.OneForOne)

    let init_state = GossipState(
                        0,
                        10,
                        main_sub,
                        dict.from_list([]),
                        neb_list: [],
                    )


    let #(builder, nodes_list) = topology.create_connections(
                                    num_nodes,
                                    init_state,
                                    handle_gossip,
                                    sup_builder,
                                    topology,
                                )

    let _ = supervisor.start(builder)
    let _ = list.fold(nodes_list, 1, fn (id, a) {

                    let topology.NodeMappings(parent_actor, neb_actors) = a

                    process.send(parent_actor, InitActorState(neb_actors, id))

                    id + 1
                }
    )

    let assert [topology.NodeMappings(first, _), ..] = nodes_list

    process.send(first, HearRumor(0xA0))

    list.range(1, num_nodes) 
    |> list.each(fn(_) {process.receive(main_sub, 1000)})

}

fn handle_gossip(
   state: GossipState, 
   msg: GossipMessage
   ) -> actor.Next(GossipState, GossipMessage) {
    
    
    case msg {

        InitActorState(neb_actors, id) -> {

            let new_state = GossipState(
                                ..state,
                                id: id,
                                neb_list: neb_actors
                            )
            echo new_state 
            actor.continue(new_state)
        }


        HearRumor(rumor_id) -> {
            //io.println("[GOSSIP_ACTOR]: got rumor " <> int.to_string(rumor_id) <> " in actor " <> int.to_string(state.id))

            let increment_count = fn(x) {

                case x {

                    Some(rumor_count) -> {

                        rumor_count + 1
                    }

                    None -> 1
                }
            }

            let new_state = GossipState(
                                ..state,
                                rumor_map: dict.upsert(state.rumor_map, rumor_id, increment_count)
                            )
            let assert Ok(rumor_heard_count) = dict.get(new_state.rumor_map, rumor_id) 

            case rumor_heard_count < state.max_rumors { 

                True -> {
                    list.each(state.neb_list, fn(neb_sub) {
                                          process.send(neb_sub, HearRumor(rumor_id))
                                      }
                    )
                    actor.continue(new_state)
                }

                False -> {

                    io.println("[GOSSIP_ACTOR]: " <> int.to_string(state.id) <> " finished rumor sending" )
                    process.send(state.main_sub, Nil)
                    actor.stop()
                }
            }


        }
    }
}
