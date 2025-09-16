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

### Bonus Details
```
gleam run <num_nodes> <algorithm> <topology> [--xxxx-failure failure_rate timeout]
```
- --xxxx-failure - this value can be either --link-failure or --node-failure
- failure rate has to be of type float '0.X' even 0 must be '0.0'
- timeout is in terms of milliseconds

- sample: 
```
gleam run 100 full gossip --link-failure 0.1 100
```
- the timeout option is used to dictate how long the link or node is down before being bought back up
- NOTE: setting this value to 0 will end up with nodes not reaching consensus and the program will only exit on SIGINT, SIGKILL or after 100000 milliseconds since the start of the deadlock
