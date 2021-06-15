# Overview

This is a built-in module to environment [pip-templates-env-master](https://github.com/pip-templates/pip-templates-env-master). 
This module stores scripts for management local timescale database running in kubernetes cluster.

# Usage

- Download this repository
- Copy *timescale* folder to master template
- Add content of *.ps1.add* files to correspondent files from master template
- Add content of *config/config.timescale.json.add* to json config file from master template and set the required values

# Config parameters

Config variables description

| Variable | Default value | Description |
|----|----|---|
| timescale.pg_version | "12" | Postgres version (must be 11 or higher to use with Docker) |
| timescale.name | "piplocal" | Name for the timescale DB |
| timescale.username | "pipadmin" | Username for the timescale DB |
| timescale.password | "PIPadmin2021#" | Password for the timescale DB |
