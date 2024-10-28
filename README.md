# axi4_lite_uvc

## Overview
This project implements a Universal Verification Methodology (UVM) based verification environment for the AXI4-Lite protocol, structured around a top-level testbench. The environment integrates two primary agents: a Master Agent and a Slave Agent, each simulating the behavior of AXI4-Lite transactions in various test scenarios.

## Architecture
![image](https://github.com/user-attachments/assets/e40815a9-7dbd-4836-9754-ca42e6d1a440)

## Components

### Master Agent
The Master Agent is responsible for handling both read and write transactions. It includes:
- **Write Sequencer**: Generates sequence items specifically for write operations.
- **Read Sequencer**: Generates sequence items specifically for read operations.
- **Driver**: Translates and applies the generated transactions onto the master interface.
- **Monitor**: Observes bus activity, records transactions, and forwards relevant data to the scoreboard for validation.

### Slave Agent
The Slave Agent represents the Device Under Test (DUT) interface and responds to master transactions. It includes:
- **Sequencer**: Contains sequence items with delayed responses to emulate realistic slave behavior.
- **Driver**: Generates responses and manages data exchanges accordingly.
- **Monitor**: Tracks bus activity and forwards data to the scoreboard for validation.

### Scoreboard
The Scoreboard validates the accuracy of each transaction by comparing observed and expected results. It gathers data from both Master and Slave Monitors, flagging any discrepancies to ensure protocol adherence.

### Coverage
Coverage metrics assess the completeness of the tests. Separate covergroups track coverage for read and write operations, as well as specific scenarios like back-to-back transactions and reads from empty addresses.

### Interface
The Interface provides a communication layer between the Master and Slave Agents.

## Configuration Objects
The environment uses two configuration objects to manage settings across the verification components:
- **axi4_lite_env_cfg**: Specifies the presence of the master and slave agents (`has_master_agent`, `has_slave_agent`).
- **axi4_lite_cfg**: Configures checks, coverage settings, agent type, policy, and read behavior (`has_checks`, `has_coverage`, `agent_type`, `policy`, `read_behaviour`).

## Tests
The test suite includes a base test, along with a set of directed and random tests. 
