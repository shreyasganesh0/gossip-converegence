import gleam/int
import gleam/list.{ Continue, Stop}

import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision
import gleam/otp/actor

import gleam/erlang/process

pub fn start_actors(
    num_nodes: Int, 
    state: state,
    handler: fn(state, message) -> actor.Next(state, message),
    sup_builder: supervisor.Builder
    ) -> #(supervisor.Builder, List(process.Subject(message))) {


    let actor_list: List(process.Subject(message)) = []

    list.range(1, num_nodes)
    |> list.fold(#(sup_builder, actor_list), fn(acc, _a) {
                 
                    let #(builder, list) = acc
                    let actor = start_actor(handler, state)

                    let assert Ok(actor_sub) = actor

                    #(
                    supervisor.add(builder, supervision.worker(fn() {actor})),
                    [actor_sub.data, ..list]
                    )

                 }
       )

}

fn start_actor(
    handler: fn(state, message) -> actor.Next(state, message), state: state
    ) -> actor.StartResult(process.Subject(message)) {

        actor.new(state)
        |> actor.on_message(handler)
        |> actor.start
}

pub fn get_random_list_element(element_list: List(a)) -> #(Int, a) {

            let send_idx = list.length(element_list)
            |> int.random

            let assert Ok(tmp) = list.first(element_list)
            list.fold_until(element_list, #(0, tmp), fn(tup, actor) {

                                                                    let #(idx, _curr_actor) = tup
                                                                    case idx < send_idx {

                                                                        True -> Continue(#(
                                                                                            idx + 1, 
                                                                                            actor
                                                                                         )
                                                                                )

                                                                        False -> Stop(#(idx, actor))
                                                                    }
                                                                }
                                    )
}
