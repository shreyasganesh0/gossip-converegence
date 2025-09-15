import gleam/int
import gleam/float
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

fn find_first_factor(n: Int, from from: Int) -> Int {

  case from <= 1 {

    True -> 1

    False -> { 

      case n % from == 0 {

        True -> from

        False ->  find_first_factor(n, from: from - 1)
      }
    }
  }
  
}

fn find_best_factors(n: Int) -> #(Int, Int, Int) {

    let assert Ok(c) =  float.power(int.to_float(n), 1.0 /. 3.0) 
    let cbrt = float.round(c)

    let h = find_first_factor(n, from: cbrt)

    let area = n / h
    let assert Ok(s) = float.square_root(int.to_float(area)) 
    let sqrt = float.round(s)
    let d = find_first_factor(area, from: sqrt)

    let w = area / d

    #(w, d, h)
}

pub fn factorize_grid(n: Int) -> #(Int, #(Int, Int, Int)) {
  let #(w, d, h) = find_best_factors(n)

  case w > 1 && d > 1 {
    True -> #(n, #(w, d, h))
    False -> factorize_grid(n + 1)
  }
}
