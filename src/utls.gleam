import gleam/list

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
