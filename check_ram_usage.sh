#!/bin/bash

# Check which process is using the most RAM
ps aux --sort=-%mem | head -n 10
