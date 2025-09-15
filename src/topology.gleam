import gleam/otp/static_supervisor as supervisor
import gleam/otp/actor

import gleam/erlang/process

import gleam/list

import utls

type Dimension {

    Dimension(
        node_count: Int,
        w: Int,
        d: Int,
        h: Int,
    )
}

pub type Type {

    Full

    Grid3D

    Line

    Imp3D
}

pub type NodeMappings(message) {

    NodeMappings(curr_actor: process.Subject(message), neighbors: List(process.Subject(message)))
}

pub fn create_connections(
    num_nodes: Int,
    init_state: state,
    msg_handler: fn(state, message) -> actor.Next(state, message),
    sup_builder: supervisor.Builder,
    topology: Type,
    ) -> #(supervisor.Builder, List(NodeMappings(message))) {

    assert num_nodes > 0

    let #(node_count, topo_creator) = case topology {

        Full -> #(Dimension(num_nodes, 0, 0, 0), full)

        Grid3D -> {

            let #(node_count, #(w, d, h)) = utls.factorize_grid(num_nodes)
            #(Dimension(node_count, w, d, h), grid3d)
        }

        Line -> #(Dimension(num_nodes, 0, 0, 0), line)

        Imp3D -> {

            let #(node_count, #(w, d, h)) = utls.factorize_grid(num_nodes)

            #(Dimension(node_count, w, d, h), imp3d)
        }
    }

    let Dimension(num_nodes, _, _, _) = node_count
    let #(builder, actor_list) = utls.start_actors(num_nodes, init_state, msg_handler, sup_builder)

    #(builder, topo_creator(node_count, actor_list))

}

fn full(
    _node_count: Dimension, 
    actor_list: List(process.Subject(message))
        ) -> List(NodeMappings(message)) {

    let mapping_list: List(NodeMappings(message)) = []
    list.fold(actor_list, mapping_list, fn(node_list, actor) {

            
            [NodeMappings(curr_actor: actor, neighbors: list.filter(actor_list, fn(a) {

                                                                                   a != actor 
                                                                                }
                                                        )
                         ),
            ..node_list
            ]
        }
    )
}

fn grid3d(
    node_count: Dimension,
    actor_list: List(process.Subject(message))
    ) -> List(NodeMappings(message)) {

    let Dimension(num_nodes, w, d, h) = node_count
    
    let indexed_actors = list.index_map(actor_list, fn(actor, i) { #(i, actor) })

    list.index_map(actor_list, fn(actor, i) {

            let z = i / {w * d}
            let y = {i % {w * d}}/ w
            let x = i % w

            let potential_neighbor_coords = [
              #(x + 1, y, z),
              #(x - 1, y, z),
              #(x, y + 1, z),
              #(x, y - 1, z),
              #(x, y, z + 1),
              #(x, y, z - 1),
            ]

            let neighbors = list.filter_map(potential_neighbor_coords,
                                            fn(coord) {


                                                let #(nx, ny, nz) = coord
                                                let is_in_bounds = nx >= 0 && nx < w &&
                                                        ny >= 0 && ny < d && nz >= 0 && nz < h

                                                case is_in_bounds {

                                                    True -> {
                                                        let neighbor_index = {nz * w * d} + {ny * w} + nx

                                                        case neighbor_index < num_nodes {

                                                            True -> list.key_find(
                                                                    indexed_actors,
                                                                    find: neighbor_index
                                                                  )

                                                            False -> Error(Nil)
                                                        }
                                                    }

                                                    False -> Error(Nil)
                                                }
                                            }
                            )

            NodeMappings(curr_actor: actor, neighbors: neighbors)
        }
    ) 
}

fn line(
    _node_count: Dimension,
    actor_list: List(process.Subject(message))
    ) -> List(NodeMappings(message)) {

    let tmp_list = actor_list

    
    case tmp_list {


        [first] -> [NodeMappings(first, [])]

        [first, second] -> {
            [NodeMappings(first, [second]), NodeMappings(second, [first])]
        }

        [first, second, ..] -> {

            let mapping_list = [NodeMappings(first, [second])]

            let #(map_list, last_trip) = list.window(actor_list, 3)
            |> list.fold(#(mapping_list, []), fn(duo, curr_triple) {

                            let #(node_list, _) = duo 
                            let assert [first, second, third] = curr_triple
                            #(
                            [NodeMappings(second, [first, third]), ..node_list],
                            curr_triple
                            )
                        }
                )

            let assert [_, b, c] = last_trip
            [NodeMappings(c, [b]), ..map_list]
        }

        _ -> []
    }

}

fn imp3d(
    node_count: Dimension,
    actor_list: List(process.Subject(message))
    ) -> List(NodeMappings(message)) {

    let Dimension(num_nodes, w, d, h) = node_count
    
    let indexed_actors = list.index_map(actor_list, fn(actor, i) { #(i, actor) })

    list.index_map(actor_list, fn(actor, i) {

            let z = i / {w * d}
            let y = {i % {w * d}}/ w
            let x = i % w

            let potential_neighbor_coords = [
              #(x + 1, y, z),
              #(x - 1, y, z),
              #(x, y + 1, z),
              #(x, y - 1, z),
              #(x, y, z + 1),
              #(x, y, z - 1),
            ]

            let neighbors = list.filter_map(potential_neighbor_coords,
                                            fn(coord) {


                                                let #(nx, ny, nz) = coord
                                                let is_in_bounds = nx >= 0 && nx < w &&
                                                        ny >= 0 && ny < d && nz >= 0 && nz < h

                                                case is_in_bounds {

                                                    True -> {
                                                        let neighbor_index = {nz * w * d} + {ny * w} + nx

                                                        case neighbor_index < num_nodes {

                                                            True -> list.key_find(
                                                                    indexed_actors,
                                                                    find: neighbor_index
                                                                  )

                                                            False -> Error(Nil)
                                                        }
                                                    }

                                                    False -> Error(Nil)
                                                }
                                            }
                            )

            NodeMappings(curr_actor: actor, neighbors: neighbors)
        }
    ) 
    |> list.map(fn(mapping) {

                     let NodeMappings(act, nebs) = mapping

                     let candidates = list.filter(actor_list, fn(potential) {
                                                                potential != act && 
                                                                    !list.contains(
                                                                        nebs,
                                                                        potential
                                                                    )
                                                              }
                     )

                     case candidates {

                         [] -> mapping

                         [first, ..] -> NodeMappings(curr_actor:act, neighbors: [first, ..nebs])

                     } 

                 }
       )
}
