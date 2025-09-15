import subprocess
import re
import pandas as pd
import matplotlib.pyplot as plt

NODES = [10, 20, 50, 100, 200, 400, 500, 1000, 2000, 3000, 4000]

TOPO = ["full", "line", "3D", "imp3D"]

ALGO = ["gossip", "push-sum"]

def run_sim(num_nodes, topology, algorithm):
    """Runs the Gleam simulation and returns the convergence time."""
    command = f"gleam run {num_nodes} {topology} {algorithm}"
    print(f"Executing: {command}")
    
    try:
        # FIX 1: Added text=True to decode output to a string
        result = subprocess.run(
            command.split(), 
            capture_output=True, 
            text=True, 
            check=True,
            timeout=100000
        )
        
        # FIX 3: Corrected the spelling of "convergence" and improved the number capture
        match = re.search(r"Time.*?convergence: (\d+\.\d+)", result.stdout)
        
        if match:
            time_taken = float(match.group(1))
            print(f"  -> Success! Time: {time_taken:.6f}s")
            return time_taken
        else:
            print("  -> Error: Could not parse time from output.")
            return None
            
    # FIX 2: Made the exception handling specific to subprocess errors
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
        print(f"  -> Error executing or command timed out: {e}")
        return None

def main():

    """
    Run all simulations, store results in memory, and generate plots.
    """
    # 1. --- Data Collection ---
    print("--- Starting Data Collection ---")
    results_list = [] # Use a list to store results in memory

    for algorithm in ALGO:
        for topology in TOPO:
            for size in NODES:
                time = run_sim(size, topology, algorithm)
                if time is not None:
                    # Append results as a dictionary to the list
                    results_list.append({
                        'num_nodes': size,
                        'topology': topology,
                        'algorithm': algorithm,
                        'time': time
                    })
    
    print("\n--- Data Collection Finished ---")

    if not results_list:
        print("No data was collected. Exiting.")
        return

    data_df = pd.DataFrame(results_list)

    for algo in ALGO:
        print(f"Generating plot for '{algo}' algorithm...")
        plt.figure(figsize=(12, 7))
        
        algo_data = data_df[data_df['algorithm'] == algo]
        
        for topology in sorted(algo_data['topology'].unique()):
            topo_data = algo_data[algo_data['topology'] == topology].sort_values('num_nodes')
            if not topo_data.empty:
                plt.plot(topo_data['num_nodes'], topo_data['time'], marker='o', linestyle='-', label=topology)

        plt.title(f"Convergence Time vs. Network Size for '{algo.upper()}'", fontsize=16)
        plt.xlabel("Network Size (numNodes)", fontsize=12)
        plt.ylabel("Convergence Time (seconds)", fontsize=12)
        plt.xscale('log')
        plt.yscale('log')
        plt.legend(title="Topology")
        plt.grid(True, which="both", linestyle='--', linewidth=0.5)
        plt.tight_layout()

        output_filename = f"plots/{algo}_convergence_plot.png"
        plt.savefig(output_filename, dpi=300)
        print(f"Plot saved as '{output_filename}'")
        
    plt.show() 

if __name__ == "__main__":
    main()

