# Build-Deploy Chain

## Introduction
The goal of this document is to describe what it should take to bring up and update a production environment on AWS.

To help focus the subject - imagine what steps would be required in case of a disaster (think of this as an outline of a DR plan), or when having to bring the environment from scratch in a new Data Centre.

I'll try to explain this by starting at the _tail_ of the process (i.e. what a running production environment looks like) and work backwards.

Incidentally, this is also the proposed order for gradual rollout of this process on top of the existing process. (i.e. start by automating the production environment, then automate the AMI creation etc).

The document uses the lab exercise just as a concrete example where relevant.

## Final State
The production environment runs an AWS Elastic Load Balancer (ELB), pointed to by an Elastic IP, resolved via Route 53 DNS.

Behind the ELB there is an AutoScaling Group (AS) which starts up and shuts down EC2 instances of a specific AMI.

The AMI runs Apache with a page displaying "Hello World" when accessed on port 80.

## Bringing up the environment
The environment is described in a CloudFormation template.

The CloudFormation template also contains the specific AMI ID as the default of an input parameter. This way the template is completely self-contained and there is a full trail of what was used when.

A script using AWS API is used to bring up the stack from the template.

The deployment script is executed through a [TeamCity Build](https://www.jetbrains.com/teamcity/features/deployment.html)

## Production Updates
The production environment is updated by a process triggered through the CI system to "push to production". The process updates the production environment's CloudFormation template, pushes it to Git and runs CloudFormation "update-stack" operation.

For example, when a new version of the software is installed (e.g. a new version of StreamCo site, or a security update from the OS vendor) a new AMI is created and its id is updated in the CloudFormation template.

## Change Testing
Changes in general, and in the CloudFormation template in particular, are tested in an environment similar to the production environment. This process is executed using a TeamCity Build.

The testing involves:

* bring up the test CloudFormation stack with a similar configuration to _current_ production environment
* (perhaps snapshot the production databases for use in the test)
* update the AMI id in the test CloudFormation stack (or other changes in the environment)
* execute a CloudFormation "update stack" operation
* verify that the environment still behaves as expected
* simulate a rollback
* verify that the environment still behaves as expected after the rollback

The goal of this process is to verify the exact process which is going to be used to update and rollback the production environment.

## AMI Generation
AMI's are created using [Packer](https://packer.io/) and contain a fully configured system ready to run as soon as the instance is up. Puppet or other generation/testing tools are _not_ installed on these AMI's.

A script wraps the execution of Packer and updates the CloudFormation template with the new AMI id.

Packer takes a base AMI, a Puppet configuration and rspec/serverspec tests, builds the AMI and executes the tests.

# Development Environment
Development is done on the user's laptop and changes are pushed to a per-task git branch.

Developers can test their changes before committing to Git by deploying them to a local [Vagrant](https://www.vagrantup.com/), the developer simply runs "vagrant provision" (assuming the vagrant box(es) are already up). The Vagrant box re-provisions accesses through a shared mounted file system.

The Vagrant provision process would probably involve running Puppet to update the environment and rspec tests to verify it.

The same steps of Puppet + Rspec are executed by the Packer process to generate and verify the final AMI's.

TeamCity can pick the branches and automatically execute test plans on them as soon as a change is pushed, this way it's easy to tell whether the branch is stable before merging it to master.

## Development Environment Setup
A new development station can be setup from scratch and kept up to date by fetching a shell script (using curl/wget) and executing it. The script will:

* Keep itself up to date (fetch a new version of itself if found)
* Install or verify availability of tools and versions (Vagrant, VirtualBox, AWS cli)
* Clone the GitHub repo locally
* Setup/fetch AWS credentials

# TeamCity Configuration
The TeamCity server software and slaves are set up through Puppet.

TeamCity build configuration is done using as much text files and scripting as possible.
[TeamCity Configuration Template] (https://confluence.jetbrains.com/display/TCD8/Build+Configuration+Template) are a good start, but I'd look for a way to configure the plans through some sort of a scripting API.

My moto is: _"If you have to point and click to configure something, you are doing it wrong."_

# Monitoring
Monitoring should be considered an integral part of any change in the code, and of course should be configured automatically by the automatic provisioning process.

# Disaster Recovery Process
Coming back to the idea of focusing on Disaster Recovery - the principle is that in case of a disaster, all we'll need is our Git repository and a Mac/Linux laptop.

Another point is that in order to bring the system up as fast as possible, perhaps it will be useful to bypass the restoration of the CI system at first and do the deployment directly to production from a development station. This is subject for debate about the pros (presumed speed to bring back the site) vs. cons (higher risk of error).

The DR process will roughly involve:

* Setup a development station as mentioned above under [Development Environment Setup](#Development Environment Setup)
* Rebuild images using Packer
* (restore state data from backup?)
* Create the CloudFormation stack with the created image
* Reconfigure whatever is necessary to configure in Akamai
* Rebuild the rest of the system (e.g. the TeamCity server)

This is not the only way to recover from a disaster - AMI backups can be used to bring up the system if they survive a disaster - but if for some reason we don't have such backups then the above can be used to bring the system back from absolute zero.

