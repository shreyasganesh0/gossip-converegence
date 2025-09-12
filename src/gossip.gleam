import gleam/dict.{type Dict}

import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor

import gleam/erlang/process

import topology
import utls

pub type GossipMessage {

    Rumor(id: Int)
}

pub type RumorMap {

    RumorMap(count_map: Dict(Int, Int))
}

pub type GossipState {

    GossipStateTmp

    GossipState(
        id: Int,
        rumor_map: RumorMap,
    )
}

pub fn start(num_nodes: Int, topology: topology.Type) {

    let main_sub = process.new_subject()

    let sup_builder = supervisor.new(supervisor.OneForOne)

    let init_state = GossipStateTmp
    let #(builder, actors_list) = utls.start_actors(num_nodes, init_state, handle_gossip, sup_builder)

    supervisor.start(builder)

    process.receive_forever(main_sub)

    let _nodes_list = topology.create_connections(actors_list, topology)
}

fn handle_gossip(
   state: GossipState, 
   msg: GossipMessage
   ) -> actor.Next(GossipState, GossipMessage) {
    
    
}
