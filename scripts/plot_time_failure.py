import subprocess
import re
import pandas as pd
import matplotlib.pyplot as plt
import os

NODES = [10, 50, 100, 200, 500, 1000]
TOPO = ["full", "line", "3D", "imp3D"]
ALGO = ["gossip", "push-sum"]

FAILURE_TYPES = ["none", "node-failure", "link-failure"]
FAILURE_RATES = [0.1, 0.2, 0.4]
FAILURE_TIMEOUT = 100

def run_sim(num_nodes, topology, algorithm, failure_type="none", failure_rate=0.0, timeout=0):
    if failure_type == "none":
        command = f"gleam run {num_nodes} {topology} {algorithm}"
    else:
        command = f"gleam run {num_nodes} {topology} {algorithm} --{failure_type} {failure_rate} {timeout}"
    
    print(f"Executing: {command}")
    
    try:
        result = subprocess.run(
            command.split(), 
            capture_output=True, 
            text=True, 
            check=True,
            timeout=10000
        )
        
        match = re.search(r"Time.*?convergence: (\d+\.\d+)", result.stdout)
        
        if match:
            time_taken = float(match.group(1))
            print(f"  -> Success! Time: {time_taken:.6f}s")
            return time_taken
        else:
            print("  -> Error: Could not parse time from output.")
            print(f"     Output: {result.stdout.strip()}")
            return None
            
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
        print(f"  -> Error executing or command timed out: {e}")
        if hasattr(e, 'stderr'):
            print(f"     Stderr: {e.stderr.strip()}")
        return None

def main():
    print("--- Starting Data Collection ---")
    results_list = [] 

    for algorithm in ALGO:
        for topology in TOPO:
            for size in NODES:
                for f_type in FAILURE_TYPES:
                    if f_type == "none":
                        time = run_sim(size, topology, algorithm, failure_type='none')
                        if time is not None:
                            results_list.append({
                                'num_nodes': size, 'topology': topology,
                                'algorithm': algorithm, 'time': time,
                                'failure_type': 'none', 'failure_rate': 0.0
                            })
                    else:
                        for f_rate in FAILURE_RATES:
                            time = run_sim(size, topology, algorithm, f_type, f_rate, FAILURE_TIMEOUT)
                            if time is not None:
                                results_list.append({
                                    'num_nodes': size, 'topology': topology,
                                    'algorithm': algorithm, 'time': time,
                                    'failure_type': f_type, 'failure_rate': f_rate
                                })
    
    print("\n--- Data Collection Finished ---")

    if not results_list:
        print("No data was collected. Exiting.")
        return

    data_df = pd.DataFrame(results_list)
    
    if not os.path.exists("plots"):
        os.makedirs("plots")

    for algo in ALGO:
        algo_data = data_df[data_df['algorithm'] == algo]
        
        for f_type in ["node-failure", "link-failure"]:
            print(f"Generating plot for '{algo}' algorithm with '{f_type}'...")
            plt.figure(figsize=(14, 8))
            
            plot_data = algo_data[(algo_data['failure_type'] == 'none') | (algo_data['failure_type'] == f_type)]

            for topology in TOPO:
                topo_data = plot_data[plot_data['topology'] == topology].sort_values('num_nodes')
                if topo_data.empty:
                    continue

                baseline = topo_data[topo_data['failure_type'] == 'none']
                if not baseline.empty:
                    p = plt.plot(baseline['num_nodes'], baseline['time'], marker='o', linestyle='-', label=f'{topology} (baseline)')
                    line_color = p[0].get_color()
                
                for rate in sorted(FAILURE_RATES):
                    failure_data = topo_data[topo_data['failure_rate'] == rate]
                    if not failure_data.empty:
                        plt.plot(failure_data['num_nodes'], failure_data['time'], 
                                 marker='x', linestyle='--', color=line_color, 
                                 label=f'{topology} (rate: {rate})')

            plt.title(f"'{algo.upper()}' Convergence with {f_type.replace('-', ' ').title()}", fontsize=16)
            plt.xlabel("Network Size (numNodes)", fontsize=12)
            plt.ylabel("Convergence Time (seconds)", fontsize=12)
            plt.xscale('log')
            plt.yscale('log')
            plt.legend(title="Topology & Failure Rate", bbox_to_anchor=(1.04, 1), loc="upper left")
            plt.grid(True, which="both", linestyle='--', linewidth=0.5)
            plt.tight_layout(rect=[0, 0, 0.85, 1])

            output_filename = f"plots/{algo}_{f_type}_comparison.png"
            plt.savefig(output_filename, dpi=300)
            print(f"Plot saved as '{output_filename}'")
            
    plt.show()

if __name__ == "__main__":
    main()
