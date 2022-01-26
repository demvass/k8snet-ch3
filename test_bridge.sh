#!/bin/bash

# enp0s3 - 10.0.2.15 - Default GW 10.0.2.2

echo 1 > /proc/sys/net/ipv4/ip_forward

# Create namespaces
ip netns add green
ip netns add blue

# Create bridge
ip link add vnet0 type bridge
ip link set vnet0 up

# Create veth pairs
ip link add veth-green type veth peer name veth-green-br
ip link set veth-green netns green
ip link set veth-green-br master vnet0

ip link add veth-blue type veth peer name veth-blue-br
ip link set veth-blue netns blue
ip link set veth-blue-br master vnet0

# Assign IP addresses
ip -n green addr add 10.0.3.1/24 dev veth-green
ip -n blue addr add 10.0.3.2/24 dev veth-blue

ip -n green link set veth-green up
ip -n blue link set veth-blue up
ip link set veth-green-br up
ip link set veth-blue-br up

# Checkpoint: connectivity between veth pairs

# Connectivity between host and namespaces
ip addr add 10.0.3.3/24 dev vnet0

# Checkpoint: connectivity between veth pairs and host

# Reaching out to a different node outside
ip netns exec green ip route add 10.0.2.0/24 via 10.0.3.3
ip netns exec blue ip route add 10.0.2.0/24 via 10.0.3.3
iptables -t nat -A POSTROUTING -s 10.0.3.0/24 -j MASQUERADE

# Reaching the outer world
ip netns  exec green ip route add default via 10.0.3.3
ip netns exec blue ip route add default via 10.0.3.3

