import gleam/otp/static_supervisor as supervisor
import gleam/otp/actor

import gleam/erlang/process

import gleam/list

import utls

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


    let #(node_count, topo_creator) = case topology {

        Full -> #(num_nodes, full)

        Grid3D -> {

            let node_count = case num_nodes % 4 == 0 {

                True -> {

                    case num_nodes < 8 {
                        
                        True -> 8 //base case minimum 8 nodes

                        False -> num_nodes
                    }
                }

                False -> {

                    {num_nodes / 4} * 4 // round down to a multiple of 4
                }
            } 
            #(node_count, grid3d)
        }

        Line -> #(num_nodes, line)

        Imp3D -> {
            let node_count = case num_nodes % 4 == 0 {

                True -> {

                    case num_nodes < 8 {
                        
                        True -> 8 //base case minimum 8 nodes

                        False -> num_nodes
                    }
                }

                False -> {

                    {num_nodes / 4} * 4 // round down to a multiple of 4
                }
            } 
            #(node_count, imp3d)
        }
    }

    let #(builder, actor_list) = utls.start_actors(node_count, init_state, msg_handler, sup_builder)

    #(builder, topo_creator(actor_list))

}

fn full(actor_list: List(process.Subject(message))) -> List(NodeMappings(message)) {

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

fn grid3d(_actor_list: List(process.Subject(message))) -> List(NodeMappings(message)) {

    let mapping_list: List(NodeMappings(message)) = []


}

fn line(_actor_list: List(process.Subject(message))) -> List(NodeMappings(message)) {todo}
fn imp3d(_actor_list: List(process.Subject(message))) -> List(NodeMappings(message)) {todo}
