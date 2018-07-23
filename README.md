# Terraform Azure cluster

Scripts and Terraform configuration to setup a set of servers in Azure.

## Getting started

Start by changing the configuration values in `run.sh`, you will need to setup the number of nodes you want (Linux and Windows) and also the username/password for the machines. After changing the config do `./run.sh` to initiate the cluster.

To destroy the cluster run `./run.sh destroy`.

## Description

The following ports are open to the internet on each machine:

* 22 - SSH
* 3389 - RDP
* 5986 - WinRM

If needed you can change this in `main.tf` under `azurerm_network_security_group`. A private IP is also assigned for each machine, use these to setup your cluster.

The Linux image uses `Ubuntu 16.04` and Windows uses `Windows Server with Containers`.


