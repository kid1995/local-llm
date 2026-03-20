#!/bin/bash

# Check which process is using the most RAM
ps aux -o pid,comm,%mem | sort -k3,3nr | head -n 5
