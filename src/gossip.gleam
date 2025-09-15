import gleam/list
import gleam/int
import gleam/float
import gleam/io
import gleam/option.{Some, None}
import gleam/dict.{type Dict}
import gleam/time/duration
import gleam/time/timestamp

import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor

import gleam/erlang/process

import topology
import utls

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
        finished: Bool,
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
                        False,
                        neb_list: [],
                    )


    let #(builder, nodes_list) = topology.create_connections(
                                    num_nodes,
                                    init_state,
                                    handle_gossip,
                                    sup_builder,
                                    topology,
                                )
    let start = timestamp.system_time()

    let _ = supervisor.start(builder)
    let _ = list.fold(nodes_list, 1, fn (id, a) {

                    let topology.NodeMappings(parent_actor, neb_actors) = a

                    process.send(parent_actor, InitActorState(neb_actors, id))

                    id + 1
                }
    )

    list.each(nodes_list, fn(map_actor) {
                let topology.NodeMappings(actor, _) = map_actor
                process.send(actor, HearRumor(0xA0))
             }
    )

    list.range(1, num_nodes) 
    |> list.each(fn(_) {process.receive(main_sub, 1000000)})

    let end = timestamp.system_time()

    let diff = timestamp.difference(start, end)
               |> duration.to_seconds

    io.println("Time Taken for Gossip convergence: " <> float.to_string(diff))
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
           // echo new_state 
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

            let #(_, send_actor) = utls.get_random_list_element(state.neb_list)
            case rumor_heard_count < state.max_rumors {  

                True -> {
                    process.send(send_actor, HearRumor(rumor_id))
                    actor.continue(new_state)
                }

                False -> {
                        
                        process.send(send_actor, HearRumor(rumor_id))
                        case state.finished {
                            False -> {
                                io.println("[GOSSIP_ACTOR]: " <> int.to_string(state.id) <> " finished rumor sending" )

                                let new_state = GossipState(
                                                    ..state,
                                                    finished: True,
                                                    rumor_map: dict.upsert(state.rumor_map,
                                                                            rumor_id,
                                                                            increment_count
                                                                ),
                                                )
                                process.send(state.main_sub, Nil)
                                actor.continue(new_state)
                            }

                            True -> actor.continue(state)
                        }
                }
            }


        }
    }
}
