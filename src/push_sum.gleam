import gleam/io
import gleam/int
import gleam/float
import gleam/list

import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor

import gleam/erlang/process

import topology
import utls

pub type PushSumMessage {

    InitActorState(neb_actors: List(process.Subject(PushSumMessage)), id: Int)

    SumWeight(s: Float, w: Float)

    StartAlgo
}

pub type PushSumState {
    
    PushSumState(
        id: Int,
        changed_count: Int,
        s: Float,
        w: Float,
        sum_estimate: Float,
        main_sub: process.Subject(Nil),
        finished: Bool,
        neb_list: List(process.Subject(PushSumMessage)),
    )
}
pub fn start(num_nodes: Int, topology: topology.Type) {

    let main_sub = process.new_subject()

    let sup_builder = supervisor.new(supervisor.OneForOne)

    let init_state = PushSumState(
                        0,
                        0,
                        0.0,
                        0.0,
                        0.0,
                        main_sub,
                        False,
                        neb_list: [],
                    )


    let #(builder, nodes_list) = topology.create_connections(
        num_nodes,
        init_state,
        handle_pushsum,
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
    
    let #(_, topology.NodeMappings(start_actor, _)) = utls.get_random_list_element(nodes_list)
    process.send(start_actor, StartAlgo)

    list.range(1, num_nodes) 
    |> list.each(fn(_) {process.receive(main_sub, 1000)})
}

fn handle_pushsum(
    state: PushSumState,
    msg: PushSumMessage,
    ) -> actor.Next(PushSumState, PushSumMessage) {

    case msg {

        InitActorState(neb_actors, id) -> {

            //echo id
            let new_state = PushSumState(
                ..state,
                s: int.to_float(id),
                w: 1.0, 
                id: id,
                neb_list: neb_actors,
            )

            actor.continue(new_state)
        }

        StartAlgo -> {

            let #(_idx, send_actor) = utls.get_random_list_element(state.neb_list)
            let send_s = state.s /. 2.0
            let send_w = state.w /. 2.0

            process.send(send_actor, SumWeight(send_s, send_w))

            let new_state = PushSumState(
                                ..state,
                                s: send_s,
                                w: send_w,
                            )
            actor.continue(new_state)

        }


        SumWeight(s, w) -> {

//            io.println("[PUSHSUM_ACTOR]: " <> int.to_string(state.id) <> " received s: " <> float.to_string(s) <> " ,w: " <> float.to_string(w))

            let #(idx, send_actor) = utls.get_random_list_element(state.neb_list)
            let send_s = {state.s +. s} /. 2.0
            let send_w = {state.w +. w} /. 2.0

            let sum_estimate = send_s /. send_w
            let diff = float.absolute_value(sum_estimate -. state.sum_estimate) 

            //echo diff <=. 10.0e-10
            
            process.send(send_actor, SumWeight(send_s, send_w))
            case diff <=. 10.0e-10 {

                True -> {

                    case state.changed_count == 2 && state.finished == False {

                        True -> {

                            io.println("[PUSHSUM_ACTOR]: " <> int.to_string(state.id) <> " has terminated with sum_estimate " <> float.to_string(sum_estimate))
                            process.send(state.main_sub, Nil)
                            let new_state = PushSumState(
                                                ..state,
                                                s: send_s,
                                                w: send_w,
                                                finished: True,
                                            )
                            actor.continue(new_state) 
                        }

                        False -> {

 //                           io.println("[PUSHSUM_ACTOR]: " <> int.to_string(state.id) <> " sending invalid")
                            let new_state = PushSumState(
                                                ..state,
                                                s: send_s,
                                                w: send_w,
                                                changed_count: state.changed_count + 1,
                                            )

                            actor.continue(new_state)

                        } 
                    }
                }

                False -> {

  //                  io.println("[PUSHSUM_ACTOR]: " <> int.to_string(state.id) <> " sending valid")
                    let new_state = PushSumState(
                                        ..state,
                                        s: send_s,
                                        w: send_w,
                                        sum_estimate: sum_estimate, 
                                        changed_count: 0,
                                    )

                    actor.continue(new_state)
                }
            }

        }

    }
}
