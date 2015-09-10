# skyed

**THIS TOOL IS WORK IN PROGRESS - USE IT CAREFULLY!**

[![Build Status](https://travis-ci.org/ifosch/skyed.svg)](https://travis-ci.org/ifosch/skyed)
[![Coverage Status](https://img.shields.io/coveralls/ifosch/skyed/master.svg)](https://coveralls.io/r/ifosch/skyed)
[![Gem Version](https://badge.fury.io/rb/skyed.svg)](http://badge.fury.io/rb/skyed)

## Description

This is an automation tool to organize deploys.
Currently, it considers you're using AWS OpsWorks.

Currently, skyed provides two ways to operate it:

* Operations engineer: With which you can run things.
* Infrastructure developer mode: With which you can test your cookbooks.

### Set up

You'll need a repository containing all your chef opsworks-enabled recipes cloned into your system.
If you don't have one, you can create one doing the following:

    git init recipes

Then, add the following line to your Gemfile, creating it if you don't have one:

    gem 'skyed'

And then, run:

    bundle install

Now, commit the Gemfile, and the Gemfile.lock:

    git add Gemfile*
    git commit -m "Initial commit"

Once the gem is installed, run:

    skyed init

It will guide you through the setup process asking about the repository where you store the recipes, trying to check if the current directory is, or asking you about the location. Also will try to get the AWS credentials from the environment variables, or ask you for them. This process will create '~/.skyed', unless that file already exists, in which case it will fail before any other question.

Alternatively, if you need to run skyed but don't need to initialize it at all, you'll need to set the PKEY environment variable to point the file containing the SSH key with access to the cookbooks remote repository:

    export PKEY=~/.ssh/id_dsa
    skyed run -s Stack -l Layer snmp

## Run

This tool allows you to execute recipes on your layers by using the run command with the -s and -l options:

    skyed run -s 21097823987-2232-234234-234234234234 -l 23423423423-234234-234234-2342342342 snmp

Alternatively, you can use stack and layer names, instead of the ids.
