#!/bin/bash

# Check which process is using the most RAM
ps aux -o pid,comm,%mem --sort=-%mem | head -n 6 | tail -n 5
