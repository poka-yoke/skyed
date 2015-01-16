# skyed

**THIS TOOL IS WORK IN PROGRESS - DO NOT USE IT YET!**

[![Build Status](https://travis-ci.org/ifosch/skyed.svg)](https://travis-ci.org/ifosch/skyed)
[![Coverage Status](https://img.shields.io/coveralls/ifosch/skyed/master.svg)](https://coveralls.io/r/ifosch/skyed)

## Set up

If you'll need a repository containing all your chef opsworks-enabled recipes. If you don't have one, you can create doing the following:

    git init recipes

Or you can clone your existing one.

Then, add the following line to you Gemfile, creating it if you don't have one:

    gem 'skyed', git: 'https://github.com/ifosch/skyed.git'

Now, commit the Gemfile:

    git add Gemfile
    git commit -m "Initial commit"

And then, run:

    bundle install

Once the gem is installed, run:

    skyed init

It will guide you through the setup process asking about the repository where you store the recipes, trying to check if the current directory is, or asking you about the location. Also will try to get the AWS credentials from the environment variables, or ask you for them. This process will create '~/.skyed', unless that file already exists, in which case it will fail before any other question.
