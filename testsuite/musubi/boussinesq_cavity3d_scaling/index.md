title: Boussinesq flow in 3D cavity for scaling performance test

# Boussinesq flow in 3D cavity for scaling performance test # {#eg_boussinesq_3d}

This example employs a three-dimensional cavity benchmark to evaluate the parallel scaling performance of the coupled LBM framework. 
It extends the two-dimensional case presented in [boussinesq_2d](../boussinesq_cavity2d_coupled/index.html).

The computational domain is a cubic cavity with dimensions $L = H = W = 1$. 
The Prandtl number is set to $Pr = 0.71$, and the Rayleigh number to $Ra = 10^5$. 
The maximum lattice velocity is fixed to 0.1, corresponding to a maximum physical velocity of 68.59 in the benchmark reference. 
This choice ensures numerical stability while maintaining consistency with the reference solution.

The coupling represents a volume-to-volume data exchange between the fluid and transport solvers. 
Within ApesMate, optimal performance for this configuration was obtained using

```lua
share_domain = true
```

This example provides setup files for both coupled and standalone solver configurations, as well as template scripts for performance analysis.

In `musubi_fluid.lua` and `musubi_T.lua`, the setup of variables `T` and `velocity_fluid` can be can be selectively enabled or disabled. This allows the user to switch between:
- standalone Musubi fluid solver,
- standalone Musubi passive scalar solver,
- fully coupled ApesMate simulation.

The reference test is tested on [**Snellius supercomputer**](https://www.surf.nl/diensten/rekenen/snellius-de-nationale-supercomputer) hosted by [**SURF**](https://www.surf.nl/). 
The tests were performed on the **Genoa partition**, which consists of nodes equipped with two AMD EPYC~9654 processors (96~cores each, Zen~4 architecture) running at 2.4~GHz, providing a total of 192 CPU cores per node. 
Hybrid parallelization was employed using 64 MPI ranks per node and 3 OpenMP threads per rank. 
This configuration was selected to approximate a near best-case scenario for the current implementation by minimizing partitioning artifacts. 
As a result, the computational domain was partitioned into perfectly cubic subdomains, which minimizes the surface-to-volume ratio of each partition and therefore reduces halo surface area for the given number of ranks. 
The resulting measurements therefore approximate a best-case baseline for the current partitioning strategy.

The weak-scaling tests were performed on 1, 8, and 64 compute nodes.
The total number of lattice elements assigned to each node was varied according to

$$
N_{\text{node}} =
\{512,\;4096,\;32768,\;262144,\;2097152,\;16777216\}.
$$

Since each node hosts 64 MPI ranks, the number of elements per rank is

$$
N_{\text{rank}} = \frac{N_{\text{node}}}{64}.
$$

For each configuration the simulation was executed for 5000 iterations.
Periodic health-check reductions were disabled.
Consequently, no global reduction occurs during the simulation, ensuring that the measured performance reflects the solver itself rather than diagnostic overhead.

This example includes template scripts for post-processing and performance analysis:
- [plot_timing](./reference/plot_timings.py) generates runtime decomposition plots across different node counts and local workloads for the Musubi solver. The results for standalone Musubi solvers are shown in [fluid](./reference/fluid_p.png) and [T](./reference/T_p.png).
- [plot_mus_speedup_eff](./reference/plot_mus_speedup_eff.py) computes weak-scaling speedup and efficiency for standalone Musubi solvers. Results are provided for [fluid](./reference/perf_fluid_perfect.png) and [T](./reference/perf_T_perfect.png).
- [plot_speedup_eff](./reference/plot_speedup_eff.py) evaluates weak-scaling speedup and efficiency of the coupled ApesMate solver. The corresponding result is shown in [apesmate](./reference/perf_apes_p.png).
- [plot_mlups_load](./reference/plot_mlups_load.py) analyzes throughput (MLUPS) of the coupled solver as a function of local workload.
The resulting performance curve is shown in [apesmate](./reference/mlups_load_p.png)
