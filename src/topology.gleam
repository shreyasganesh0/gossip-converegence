import gleam/erlang/process

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
    actor_list: List(process.Subject(message)),
    topology: Type,
    ) -> List(NodeMappings(message)) {


    case topology {

        Full -> full(actor_list)
        Grid3D -> grid3d(actor_list)
        Line -> line(actor_list)
        Imp3D -> imp3d(actor_list)
    }

}

fn full(_actor_list: List(process.Subject(message))) -> List(NodeMappings(message)) {todo}
fn grid3d(_actor_list: List(process.Subject(message))) -> List(NodeMappings(message)) {todo}
fn line(_actor_list: List(process.Subject(message))) -> List(NodeMappings(message)) {todo}
fn imp3d(_actor_list: List(process.Subject(message))) -> List(NodeMappings(message)) {todo}
