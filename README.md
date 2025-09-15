# gossip_convergence

[![Package Version](https://img.shields.io/hexpm/v/gossip_convergence)](https://hex.pm/packages/gossip_convergence)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gossip_convergence/)

```sh
gleam add gossip_convergence@1
```
```gleam
import gossip_convergence

Further documentation can be found at <https://hexdocs.pm/gossip_convergence>.

```

## Usage
```
gleam run <num_nodes> <algorithm> <topology>
```
- num_nodes - number of nodes in the network
- algorithm - of type "full | line | 3D | imp3D"
- topology - of type "gossip | push-sum"

- Run script to generate plots 
```
source myenv/bin/activate

uv run scripts/plot_time.py
```
- plots are added to the "plots/" dir

## Implementation Details

Team Members - Shreyas Ganesh

### Details
- algorithmsn implmented are gossip and push-sum
    - both of the algorithms start all num_node number of actors with a start message
    to implment parallelism
    - All actors reach convergence by the end
        - acheived by redefining termination to be just logging and informnig the main process that
        the calculations for each actor have been completed
        - actors continue to propogate messages till the last one reaches the termination state

    - gossip terminates at 10 "heard" messages
    - push sum terminates based on the s/w ratio as stated in the documentation

