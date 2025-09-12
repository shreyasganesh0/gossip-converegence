import argv

import gleam/io
import gleam/int
import gleam/bool
import gleam/result

import gossip
import push_sum
import topology

pub type ParseError {

    InvalidArgs
    WrongArgCount(required: Int)
}


pub fn main() -> Nil {
    let ret = case argv.load().arguments {
    
        [num_nodes, topology, algorithm] -> {

             {
                use i_num_nodes <- result.try(result.map_error(int.parse(num_nodes), 
                                                                fn(_) {InvalidArgs}
                                             )
                                    )
                use ret_topo <-  result.try(case {topology == "full"}
                     |> bool.or(topology == "3D")
                     |> bool.or(topology == "line")
                     |> bool.or(topology == "imp3D")
                {
                    True -> Ok(topology)

                    False -> Error(InvalidArgs)
                })
                use ret_algo <- result.try(case {algorithm == "gossip"}
                     |> bool.or(algorithm == "push-sum")
                {

                    True -> Ok(algorithm)

                    False -> Error(InvalidArgs)
                })
                Ok(#(i_num_nodes, ret_topo, ret_algo))

            }
        }

        _, -> Error(WrongArgCount(3))
    }

    case ret {


        Ok(#(num_nodes, topology, algorithm)) -> {

            io.println("[MAIN]: starting gossip for " <> 
                "num_nodes: " <> int.to_string(num_nodes) <> 
                ", topology: " <> topology <> 
                ", algorithm: " <> algorithm
            )

            let topo = case topology {

                "full" -> topology.Full
                "3D" -> topology.Grid3D
                "line" -> topology.Line
                "imp3D" -> topology.Imp3D
                _ -> panic as "[MAIN]: this should never happen. Matched some random topo"
            }
            case algorithm {

                "gossip" -> {
                    gossip.start(num_nodes, topo)
                    Nil
                }

                _ -> {

                    push_sum.start(num_nodes, topo)
                    Nil
                }
            }
        }

        Error(err) -> {

            case err {

                InvalidArgs -> io.println("[MAIN]: sent invalid args")

                WrongArgCount(n) ->  io.println("[MAIN]: too few arguments require: " <> int.to_string(n))
            }
            io.println("[MAIN]: Usage: gossip_convergence <numNodes> <full|3D|line|imp3D> <gossip|push-sum>")
        }
    }

}
