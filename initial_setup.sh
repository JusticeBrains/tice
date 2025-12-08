#!/bin/bash

# --- Script Name: initial_setup.sh ---
# Description: Performs initial setup for a new Linux server, installing core
# development tools, PostgreSQL, Python environment tools, and Nginx.

# Set error flag: Exit immediately if any command fails
set -e

echo "Starting initial system setup..."

# 1. Update and Upgrade System
echo "--- 1. Updating package list and upgrading system packages ---"
sudo apt update
sudo apt upgrade -y

# 2. Install Core Development Dependencies
echo "--- 2. Installing core development dependencies ---"
sudo apt install -y build-essential libreadline-dev zlib1g-dev wget curl git

# 3. Install Python and PostgreSQL Development Libraries
echo "--- 3. Installing Python and PostgreSQL development libraries ---"
sudo apt install -y python3-dev libssl-dev libpq-dev

# 4. Install Core Applications (Python Venv, PostgreSQL, Nginx)
echo "--- 4. Installing Python Virtual Environment tool, PostgreSQL, and Nginx ---"
sudo apt install -y python3-venv postgresql postgresql-contrib nginx

echo "--- Setup Complete! ---"
echo "You can now perform the following next steps:"
echo "* Check PostgreSQL status: sudo systemctl status postgresql"
echo "* Check Nginx status: sudo systemctl status nginx"
echo "* Switch to the postgres user: sudo -i -u postgres"