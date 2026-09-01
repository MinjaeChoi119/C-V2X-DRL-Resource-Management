# C-V2X Radio Resource Management Using Deep Reinforcement Learning

Undergraduate thesis, Department of Automotive Engineering, Hanyang University, 2024.

In C-V2X sidelink mode 4, vehicles pick their own radio resources with no base station coordinating them. When traffic gets dense the channel congests, packets collide, and the safety messages that the whole system exists to deliver start getting lost. Congestion control decides how aggressively each vehicle backs off — and the usual approach is a fixed rule tuned to a target channel busy ratio.

This work replaces that fixed rule with a DQN agent that learns the backoff policy from the channel state, and compares it against fixed-policy baselines in simulation.

## What I implemented

The DQN was written from scratch in MATLAB, without a reinforcement-learning toolbox:

- a custom environment wrapping the simulator's channel state
- experience replay
- target-network synchronization
- manual gradient computation with clipping
- a custom Q-learning loss

## Layout

Everything lives under `WiLabV2Xsim-main_custom/`, which is the upstream simulator with my changes applied.

| Path | What it is |
| --- | --- |
| `DQN/` | The agent: network, replay buffer, training loop |
| `*_final_dqn.m` | Simulator entry points driving the DQN policy |
| `*_final_policy_85.m`, `*_final_policy_90.m` | Fixed-policy baselines at the two channel-busy-ratio targets used for comparison |
| `conferenceModel_final_85.mat`, `conferenceModel_final_90.mat` | Trained models |
| `plot_CBR_PRR.m`, `rho_plot_final.m` | Analysis and figures (channel busy ratio, packet reception ratio, vehicle density) |

`C-V2X Radio Resource Management Using Deep Reinforcement Learning.pdf` is the full thesis; `research poster.pdf` is the summary poster. Both cover the setup, results and discussion in detail.

## Running it

MATLAB with the Deep Learning Toolbox. Start from `WiLabV2Xsim_final_dqn.m` for the learned policy or `WiLabV2Xsim_final_policy_85.m` / `_90.m` for the baselines. The upstream simulator's own documentation covers configuration files and scenario setup.

## Attribution and license

This repository is a **derivative work of [WiLabV2Xsim](https://github.com/V2Xgithub/WiLabV2Xsim)**, an open-source C-V2X / IEEE 802.11p simulator developed at the University of Bologna, CNR, and WiLab/CNIT. The upstream project is licensed **GPL-3.0**, so this repository is distributed under GPL-3.0 as well, and the original `LICENSE` is preserved in `WiLabV2Xsim-main_custom/`.

Everything outside the DQN work above is upstream code and belongs to its original authors.

Please cite the simulator as its authors request:

> V. Todisco, S. Bartoletti, C. Campolo, A. Molinaro, A. O. Berthet, and A. Bazzi, "Performance analysis of sidelink 5G-V2X mode 2 through an open-source simulator," *IEEE Access*, 2021.

And this thesis as:

> Choi, M. (2024). *C-V2X Radio Resource Management Using Deep Reinforcement Learning* [Unpublished undergraduate thesis]. Department of Automotive Engineering, Hanyang University.
