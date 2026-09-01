# C-V2X Radio Resource Management Using Deep Reinforcement Learning

Undergraduate thesis, Department of Automotive Engineering, Hanyang University, 2024.
Advisor: Prof. Han-Shin Jo.

A DQN agent is trained to replace ETSI's distributed congestion control for C-V2X, and the policy it learns is then read back out as a simple rule that outperforms the standard.

## The problem

In C-V2X sidelink mode 4, vehicles choose their own radio resources with no base station coordinating them. As traffic gets denser the channel congests and packets are lost, so a distributed congestion control (DCC) algorithm has to throttle how much channel each vehicle takes.

The ETSI standard does this by looking at **channel busy ratio (CBR)** and capping the channel occupancy ratio limit accordingly:

| Measured CBR | CR limit |
| --- | --- |
| 0 – 0.3 | 1 |
| 0.3 – 0.65 | 0.03 |
| 0.65 – 0.8 | 0.006 |
| 0.8 – 1 | 0.003 |

In practice this holds CBR near 0.65, and it is not enough to keep packet delivery ratio (PDR) above the target once density climbs. That gap is what this work attacks.

## The DRL model

| | |
| --- | --- |
| **Algorithm** | DQN (Mnih et al., 2015) |
| **State** | Vehicle density, average CBR |
| **Action** | CR limit ∈ {1, 0.006, 0.003} |
| **Reward** | Amplified difference between the measured PDR and `PDR_optimal` |
| **Targets** | Trained separately for target PDR = 85% and 90% |

`PDR_optimal` is taken from the training data set as the value closest to the target PDR. The action set keeps ETSI's own packet generation intervals (T_gen = 100 / 166 / 333 ms) so the learned policy can be compared against the standard directly.

The trained model holds average PDR near the target where ETSI's algorithm does not.

## The result worth reading

Plotting the trained model's chosen action against vehicle density showed it selecting **one action per density value**. Of the two state variables it was given, only vehicle density was actually driving the decision — CBR was not.

So the black box was replaced with an explicit density-based rule, read directly off what the agent had learned:

**Target PDR = 85%**

| Vehicle density ρ [veh/km] | CR limit | T_gen |
| --- | --- | --- |
| ρ < 203 | 1 | 100 ms |
| 203 ≤ ρ < 236 | 0.006 | 166 ms |
| 236 ≤ ρ | 0.003 | 333 ms |

**Target PDR = 90%**

| Vehicle density ρ [veh/km] | CR limit | T_gen |
| --- | --- | --- |
| ρ < 172 | 1 | 100 ms |
| 172 ≤ ρ < 193 | 0.006 | 166 ms |
| 193 ≤ ρ | 0.003 | 333 ms |

Run in the simulator, this rule reproduces the DRL model's PDR curve and improves on ETSI's DCC — without any neural network at inference time.

The conclusion is not "DQN beats the standard." It is that DRL was useful as an *instrument for finding a better rule*: it surfaced that density, not CBR, is the variable that matters, and the resulting algorithm is simple enough to state in three lines.

## Simulation parameters

Thesis Table 1, via the WiLabV2Xsim simulator.

| Parameter | Value |
| --- | --- |
| Vehicle density | 100 – 360 veh/km |
| Resource keep probability | 0.8 |
| Message size | 300 B |
| Bandwidth | 10 MHz |
| Road width | 3.5 m |
| Mean vehicle speed | 50 km/h |
| TCR | 200 m |
| Target PDR | 85%, 90% |
| MCS index | 3 |
| Minimum SINR | 1.49 dB |
| Replay memory capacity | 1,000,000 |
| Mini-batch size | 768 |
| Minimum T_gen | 100 ms |

## Implementation notes

The agent is built on MATLAB's Reinforcement Learning Toolbox primitives (`rlDQNAgent`, `rlQValueRepresentation`, `rlFiniteSetSpec`, `rlFunctionEnv`, `rl.util.ExperienceBuffer`), but **the training loop is written by hand rather than calling `train()`** — epsilon-greedy action selection, replay sampling, target-Q computation, gradient evaluation against a custom loss, gradient clipping, the optimizer step, and periodic target-network synchronization are all explicit in `dcc_dqn.m`. It started from MathWorks' custom DQN training-loop example (the cartpole scaffolding is still in `DQN/`) and the environment, reward and loss were rewritten for this problem.

Critic network: 1 input → 64 → 64 → 3, ReLU. Learn rate 0.001, gradient threshold 1, discount 0.99, target update every 500 steps, Double DQN off.

The training environment is not the simulator running live. Channel results were swept in WiLabV2Xsim first (density × each action → CBR, PDR) and `myDCCStepFunction.m` steps over that table, which makes training cheap and reproducible. The learned policy and the density-based rule are then evaluated back inside the full simulator.

## Layout

Everything sits under `WiLabV2Xsim-main_custom/`, the upstream simulator with our changes applied.

| Path | What it is |
| --- | --- |
| `DQN/` | Agent, environment, reward, custom loss, training script |
| `*_final_dqn.m` | Simulator runs driven by the trained DQN policy |
| `*_final_policy_85.m`, `*_final_policy_90.m` | Simulator runs of the **proposed density-based algorithm** at each target PDR |
| `conferenceModel_final_85.mat`, `_90.mat` | Trained models |
| `plot_CBR_PRR.m`, `rho_plot_final.m` | Figures |

`C-V2X Radio Resource Management Using Deep Reinforcement Learning.pdf` is the full thesis and `research poster.pdf` the summary poster. Both carry the figures and the full discussion.

## Running it

MATLAB with the Deep Learning and Reinforcement Learning Toolboxes. `DQN/dcc_dqn.m` trains the agent; `WiLabV2Xsim_final_dqn.m` runs the learned policy in the simulator and `WiLabV2Xsim_final_policy_85.m` / `_90.m` run the proposed rule. The upstream simulator's documentation covers config files and scenario setup.

## Contributors

Two-person capstone project. I designed the study and did the DCC analysis, the DRL model and training, the interpretation of the learned policy, and the density-based algorithm and its evaluation. Jaewook An built the in-simulation measurement and export path — the CBR accumulation and per-timestep packet counters that produced the data set the agent trains on (marked in the source with `% 안재욱` comments).

## Attribution and license

This repository is a **derivative work of [WiLabV2Xsim](https://github.com/V2Xgithub/WiLabV2Xsim)**, an open-source C-V2X / IEEE 802.11p simulator from the University of Bologna, CNR, and WiLab/CNIT. Upstream is **GPL-3.0**, so this repository is GPL-3.0 as well, and the original `LICENSE` is preserved in `WiLabV2Xsim-main_custom/`. Everything outside the work described above is upstream code belonging to its original authors.

Please cite the simulator as its authors request:

> V. Todisco, S. Bartoletti, C. Campolo, A. Molinaro, A. O. Berthet, and A. Bazzi, "Performance analysis of sidelink 5G-V2X mode 2 through an open-source simulator," *IEEE Access*, Vol. 9, pp. 154–168, 2021.

And this thesis as:

> Choi, M. (2024). *C-V2X Radio Resource Management Using Deep Reinforcement Learning* [Unpublished undergraduate thesis]. Department of Automotive Engineering, Hanyang University.
