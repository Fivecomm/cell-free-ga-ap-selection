# Access Point Activation for Static Area-Wide Coverage in Cell-Free Massive MIMO Networks

This repository contains the dataset and code to reproduce results of the following conference paper:

Guillermo García-Barrios, Martina Barbi and Manuel Fuentes, "Access Point Activation for Static Area-Wide Coverage in Cell-Free Massive MIMO Networks," 2026 Joint European Conference on Networks and Communications & 6G Summit (EuCNC/6G Summit), Málaga, Spain, 2026. [Submitted]

## Abstract of the Paper

As wireless networks evolve toward sixth generation (6G), energy efficiency has become a key objective, particularly in ultra-dense deployments with extensive infrastructure. Cell-free massive multiple-input multiple-output (MIMO) enables cooperative transmission across distributed access points (APs), providing uniform service quality, but keeping all APs continuously active leads to substantial energy consumption. In many practical scenarios, networks must guarantee reliable area-wide coverage without relying on real-time user traffic, channel feedback, or dynamic reconfiguration. Such static, system-driven operating regimes arise in offline network planning, rural or low-activity deployments, emergency preparedness, and energy-saving modes during off-peak periods. In this context, we investigate the suitability of genetic algorithm (GA)–based strategies for static AP activation under strict spatial coverage constraints. Two tailored GA variants are considered: a bitstring-based approach and a probabilistic formulation that guides exploration through elite solutions. Using a realistic digital twin, simulation results show that GA-based methods can reliably identify feasible activation patterns even when valid configurations are scarce, with the probabilistic variant offering a favorable balance between reliability and computational cost. These findings position GA-based optimization as a practical and flexible tool for offline planning and system-driven operation in energy-aware cell-free networks.

## Content of Code Package

### Scripts

* `calculatePathloss.m` / `calculateRSRP.m`: Computes pathloss and received signal power matrices for all AP combinations.
* `calculateRSRP_AP.m`: Computes per-AP RSRP values for all UEs, used by greedy and local search baselines.
* `compare_baselines_solutions.m`: Executes greedy and local search baseline methods across scenarios.
* `compare_GA_solutions.m`: Executes the bitstring GA, probabilistic GA, and random selection across defined scenarios, storing results for subsequent analysis.
* `tune_GA_bitstring.m`: Performs hyperparameter tuning for the bitstring GA (population size, mutation rate, tournament size).
* `tune_GA_prob.m`: Performs hyperparameter tuning for the probabilistic GA (population size, learning rate α, patience).
* `results_baselines_performance.m`: Extracts and summarizes performance metrics (fitness, evaluations, success rate) for baseline methods.
* `results_computationTime.m`: Extracts and summarizes computation times for all methods, exporting them to Excel.
* `results_computationTime_baselines.m`: Extracts and summarizes execution time results for baseline methods.
* `results_performance.m`: Extracts coverage and RSRP results from executed GA solutions and saves a summary table with standard deviations, exporting them to Excel.

### Functions

* `computeAggregateRSRP.m`: Calculates the aggregate RSRP for each UE from a given set of active APs, accounting for transmit power, antenna efficiency, pathloss, and hardware losses.
* `evaluate_AP_set_direct.m`: Computes coverage and average RSRP by aggregating per-AP RSRP values.
* `GA_bitstring_AP_selection.m`: Implements the fixed-cardinality bitstring GA for AP selection.
* `GA_probabilistic_AP_selection.m`: Implements the probabilistic GA for AP selection.
* `getThParameters.m`: Returns 5G NR physical resource block configuration, numerology, and slot duration based on bandwidth, subcarrier spacing, and carrier frequency.
* `greedy_AP_selection.m`: Greedy AP selection baseline based on incremental coverage maximization.
* `local_search_AP_selection.m`: Local search (1-swap hill climbing) baseline initialized from greedy solution.
* `random_selection.m`: Random AP selection baseline for performance comparison.

## Usage Instructions

1. **Compute Pathloss / RSRP:**

   * Run `calculatePathloss.m` and `calculateRSRP.m` to generate the RSRP matrices for all AP combinations.
   * Run `calculateRSRP_AP.m` to generate per-AP RSRP matrices required by greedy and local search baselines.
2. **Hyperparameter tuning (optional):**

   * Bitstring GA: `tune_GA_bitstring.m`
   * Probabilistic GA: `tune_GA_prob.m`
3. **Compare GA solutions:**

   * Run `compare_GA_solutions.m` to execute all GA algorithms across scenarios. Results are saved in the `results/` folder.
   * Run `compare_baselines_solutions.m` to execute greedy and local search baselines.
4. **Result analysis:**

   * Coverage and RSRP statistics: `results_performance.m`
   * Computation times: `results_computationTime.m`
   * Baseline performance: `results_baselines_performance.m`
   * Baseline computation times: `results_computationTime_baselines.m`

**NOTE:** Greedy and local search baselines are deterministic and exhibit zero success rate under strict coverage constraints; they are included as reference heuristics commonly used in combinatorial optimization.

# Associated dataset

This repository is associated with a dataset which is is available at [https://zenodo.org/records/17177328](https://zenodo.org/records/17177328)

**NOTE:** The downloaded files should be placed in a directory named `data/`.

# Acknowledgments

This work is supported by the Spanish ministry of economic affairs and digital transformation and the European Union - NextGenerationEU [UNICO I+D 6G/INSIGNIA] (TSI-064200-2022-006).

# License and Referencing

This code package is licensed under the GPLv2 license. If you in any way use this code for research that results in publications, please cite our original article listed above.
