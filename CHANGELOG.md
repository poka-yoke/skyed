## 0.1.10 (2015-09-10)

Bug fixes:

  - Fixed bug when clone takes too much time to complete.

## 0.1.9 (2015-06-30)

Bug fixes:

  - Run command bug when not setup fails.

## 0.1.8 (2015-06-16)

Features:

  - RDS creation, creation from snapshot, destroying, and listing snapshots.

Improvements:

  - Skyed::Git module created with some Git operations.
  - Enhanced recipe exists check to use remote Git.
  - Template creation generalized in Utils.create_template.
  - Mostly all OpsWorks dependencies moved to Skyed::AWS::OpsWorks module.
  - Init command now has more options.

Bug fixes:

  - Deploy now exports credentials for Vagrant usage.

## 0.1.7 (2015-05-21)

Features:

  - Allows invoking stack and layer by name in run command.
  - Destroy command now removes automatically created user and settings.
  - Destroy waits for the instance to be deregistered.

Improvements:

  - All run command OpsWorks dependencies moved to Skyed::AWS::OpsWorks module.

## 0.1.6 (2015-05-04)

Bug Fix:

  - Fails with error when a deployment finished with anything but sucessful.

## 0.1.5 (2015-05-04)

Features:

  - Adds options to force Chef version used in stack

Other changes:

  - All AWS code moved to separate modules

## 0.1.4 (2015-04-15)

Features:

  - Fixes release process

## 0.1.3 (2015-04-15)

Features:

  - Updates README.md

## 0.1.2 (2015-04-15)

Features:

  - `run` command accepts option for custom JSON arguments.

## 0.1.1 (2015-04-14)

Features:

  - `run` command usage with `-s` and `-l` to update cookbooks and run recipes on OpsWorks Stacks and Layers.
