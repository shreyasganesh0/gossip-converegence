import gleam/erlang/process

pub type Type {

    Full

    Grid3D

    Line

    Imp3D
}

pub type Message {

    Rumor(id: Int)

    SumWeight(s: Int, w: Int)
}
pub type NodeMappings {

    NodeMappings(curr_actor: process.Subject(Message), neighbors: List(process.Subject(Message)))
}

pub fn create_connections(
    actor_list: List(process.Subject(Message)),
    topology: Type,
    ) -> NodeMappings {


    case topology {

        Full -> full(actor_list)
        Grid3D -> grid3d(actor_list)
        Line -> line(actor_list)
        Imp3D -> imp3d(actor_list)
    }

}

fn full(actor_list: List(process.Subject(Message))) -> NodeMappings {todo}
fn grid3d(actor_list: List(process.Subject(Message))) -> NodeMappings {todo}
fn line(actor_list: List(process.Subject(Message))) -> NodeMappings {todo}
fn imp3d(actor_list: List(process.Subject(Message))) -> NodeMappings {todo}
