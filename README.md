# Genetic Algorithm-Based Optimization of AP Activation for Static Coverage in Cell-Free

This repository contains the dataset and code to reproduce results of the following conference paper:

Guillermo García-Barrios, Martina Barbi and Manuel Fuentes, "Genetic Algorithm-Based Optimization of AP Activation for Static Coverage in Cell-Free," IEEE International Conference on Communications (ICC), Glasgow, Scotland, UK, 2025. [Submitted]

## Abstract of the Paper

As wireless networks advance toward 6G, energy efficiency has become a critical design objective, especially in ultra-dense deployments requiting extensive infrastructure. Cell-free massive MIMO, which eliminates traditional cell boundaries through cooperative transmission across distributed access points (APs), can provide uniform service quality but at the cost of high energy consumption if all APs remain active. A promising alternative is selective AP activation, ensuring area-wide coverage while reducing power use, even without user traffic data or real-time feedback. To address this challenge, we investigate two tailored genetic algorithm (GA) variants: a bitstring GA enforcing a fixed number of active APs, and a probabilistic GA updating activation probabilities based on elite solutions. Both efficiently explore the exponential solution space, identifying minimal AP subsets that satisfy strict received signal strength and coverage requirements. Results show that the probabilistic GA achieves near-optimal coverage with about half the runtime of the bitstring GA, providing a practical balance between performance and complexity. These findings highlight GA-based methods as lightweight alternatives to exhaustive search or data-driven approaches, contributing to the development of more sustainable and adaptable wireless infrastructures.

## Content of Code Package

### Scripts

* `calculatePathloss.m` / `calculateRSRP.m`: Computes pathloss and received signal power matrices for all AP combinations.
* `compare_GA_solutions.m`: Executes the bitstring GA, probabilistic GA, and random selection across defined scenarios, storing results for subsequent analysis.
* `tune_GA_bitstring.m`: Performs hyperparameter tuning for the bitstring GA (population size, mutation rate, tournament size).
* `tune_GA_prob.m`: Performs hyperparameter tuning for the probabilistic GA (population size, learning rate α, patience).
* `results_performance.m`: Extracts coverage and RSRP results from executed GA solutions and saves a summary table with standard deviations, exporting them to Excel.
* `results_computationTime.m`: Extracts and summarizes computation times for all methods, exporting them to Excel.

### Functions

* `computeAggregateRSRP.m`: Calculates the aggregate RSRP for each UE from a given set of active APs, accounting for transmit power, antenna efficiency, pathloss, and hardware losses.
* `getThParameters.m`: Returns 5G NR physical resource block configuration, numerology, and slot duration based on bandwidth, subcarrier spacing, and carrier frequency.
* `GA_bitstring_AP_selection.m`: Implements the fixed-cardinality bitstring GA for AP selection.
* `GA_probabilistic_AP_selection.m`: Implements the probabilistic GA for AP selection.
* `random_selection.m`: Random AP selection baseline for performance comparison.

## Usage Instructions

1. **Compute Pathloss / RSRP:** Run `calculatePathloss.m` and `calculateRSRP.m` to generate the RSRP matrices for all AP combinations.
2. **Hyperparameter tuning (optional):**

   * Bitstring GA: `tune_GA_bitstring.m`
   * Probabilistic GA: `tune_GA_prob.m`
3. **Compare GA solutions:** Run `compare_GA_solutions.m` to execute all GA algorithms across scenarios. Results are saved in the `results/` folder.
4. **Result analysis:**

   * Coverage and RSRP statistics: `results_performance.m`
   * Computation times: `results_computationTime.m`

# Associated dataset

This repository is associated with a dataset 

The dataset is available at [https://zenodo.org/records/17177328](https://zenodo.org/records/17177328) 

**NOTE:** The downloaded files should be placed in a directory named `data/`.

# Acknowledgments

This work is supported by the Spanish ministry of economic affairs and digital transformation and the European Union - NextGenerationEU [UNICO I+D 6G/INSIGNIA] (TSI-064200-2022-006).

# License and Referencing

This code package is licensed under the GPLv2 license. If you in any way use this code for research that results in publications, please cite our original article listed above.
