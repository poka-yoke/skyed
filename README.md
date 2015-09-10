# skyed

**THIS TOOL IS WORK IN PROGRESS - USE IT CAREFULLY!**

[![Build Status](https://travis-ci.org/ifosch/skyed.svg)](https://travis-ci.org/ifosch/skyed)
[![Coverage Status](https://img.shields.io/coveralls/ifosch/skyed/master.svg)](https://coveralls.io/r/ifosch/skyed)
[![Gem Version](https://badge.fury.io/rb/skyed.svg)](http://badge.fury.io/rb/skyed)

## Description

This is an automation tool to organize deploys.
Currently, it uses AWS OpsWorks.

Also currently, it provides two ways to operate it:

* Operations engineer: Allows to run things.
* Infrastructure developer mode: Enabling to do cookbook testing.

### Set up

A repository containing all the chef opsworks-enabled recipes is required, and
must be cloned into the development workstation.
This repository can be created by running the following:

    git init cookbooks

Then, add the following line to the Gemfile within this repository, creating
it if you don't have one:

    echo "gem 'skyed'" > cookbooks/Gemfile

And then, run:

    cd cookbooks
    bundle install

Now, commit both the Gemfile and the Gemfile.lock:

    git add Gemfile*
    git commit -m "Initial commit"

Once the gem is installed, run:

    skyed init

It will guide through the setup process asking about the repository's local
location where the coobooks are stored, trying to check if the current
directory is, or asking about the location. It also will try to get the AWS
credentials from the environment variables, or ask for them. This process
will create '~/.skyed', unless that file already exists, in which case it
will fail before any other question.

Alternatively, if the only need is to run skyed but without having to
initialize it at all, then set the PKEY environment variable to point the
file containing the SSH key with access to the cookbooks remote repository:

    export PKEY=~/.ssh/id_dsa
    skyed run -s Stack -l Layer snmp

## Run

This tool allows to execute recipes on specific layers by using the run
command with the -s and -l options:

    skyed run -s Stack_name -l Layer name snmp

Stack and layer ids can be used, instead of the names.

## List

The list command, with the --rds switch, lists all snapshots in AWS RDS:

    skyed list --rds

## Create

To create RDS for PostgreSQL instances, from snapshot, with the same
parameters of the original, except for the `--db-parameters-group`
and `--db-security-group` parameters:

    skyed create --rds new_instance_name rds:snapshot

Or from scratch, specifying parameters (check this list using `create --help`):

    skyed create --rds new_instance_name --size 150 --type m1.xlarge --user owner

It returns the endpoint for the new instance.

## Destroy

AWS RDS instances can be also destroyed, optionally saving a final snapshot:

    skyed destroy --rds instance_name_to_remove

## Deploy

With that command, current cookbook repository is used to deploy a local
vagrant machine.
This feature requires `.skyed` to exist with valid parameters.
