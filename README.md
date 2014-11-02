# Current running stack
You can access a running stack at http://streamcol-elasticl-1ho1berce7emk-1964054685.ap-southeast-2.elb.amazonaws.com/

Read-only user credentials to check the stack configuration will are provided via e-mail.

# Setup

This repository contains the following files:
```
├── Vagrantfile
├── description.md
├── packer-streamco.json
├── puppet
│   ├── Puppetfile
│   ├── Puppetfile.lock
│   ├── manifests
│   │   └── default.pp
│   └── modules
├── scripts
│   ├── run-cf-create
│   ├── run-cf-validate
│   ├── run-packer-aws
│   └── serverspec.sh
├── streamco.template
└── tests
    ├── spec
    │   └── streamco_spec.rb
    └── spec_helper.rb
```
The files are:

* Vagrantfile: used to bring up a development box which also pre-fetches external Puppet modules using librarian-puppet
* description.md: a high level proposal of how to setup an automated build and deploy chain
* packer-streamco.json: a Packer configuration file to burn an AMI with the Hello World configuration
* puppet/Puppetfile: a librarian-puppet configuration file to list external modules
* puppet/manifests/default.pp: a minimal Puppet manifest to install and configure Apache to serve a "Hello World" page
* puppet/modules: an empty directory were librarian-puppet will install external modules. Must exist for Vagrant to succeed.
* scripts/run-cf-create: create a CloudFormation stack using "streamco.template"
* scripts/run-cf-validate: validate the stack template
* scripts/run-packer-aws: run Packer to generate an AMI using Puppet
* streamco.template: a CloudFormation template to configure a stack using Elastic Load Balancer and Auto Scaling Group to serve "Hello World" static page.
* tests/spec/streamco_spec.rb: Serverspec tests of the Puppet configuration.

To bring up an environment (this was tested on OSX):

* Install Packer from https://packer.io/downloads.html
* [Install AWS CLI using pip](http://docs.aws.amazon.com/cli/latest/userguide/installing.html#install-with-pip)
* Provide read-write AWS access key ID and secret access key in file "../credentials.csv". Here is an example of what this file looks like (this is the format downloaded from the AWS console):
```
$ cat ../credentials.csv
User Name,Access Key Id,Secret Access Key
"amos",ACCESSKEYID20CHARS,secretaccesskey40chars
```
* run "vagrant up" - this will bring up a Vagrant box which is used for two separate functions but combined here for brevity:
    * Fetch external Puppet modules using librarian-puppet. This is done inside the Vagrant box in order to avoid the need to install and run librarian-puppet on the host laptop (this is a common "chicken-and-egg" issue with external Puppet modules in Vagrant).
    * Provide a test environment for the provisioning process using Puppet (in this case - install Apache, configure it and run Serverspec tests on it)
* run "scripts/run-packer-aws" (from the repository root directory), this will create an AMI with the following steps:
    * Install puppet from a .deb file (for proper clean work it should install Puppet locally from Gem files, or remove Puppet when done)
    * Execute Puppet using the manifest file in puppet/manifests/default.pp and the external modules which were previously installed by puppet-librarian through the Vagrant box.
    * Execute Serverspec tests.
    * Burn the AMI and output an AMI ID if all went well. Keep a note of the output AMI ID.
* Execute:
```
./scripts/run-cf-create --parameters ParameterKey=ImageId,ParameterValue=ami-AMIID
```
where ami-AMIID is the output from Packer.
This operation could take a few minutes. You can track its progress either through the AWS console or via repeated execution of "aws cloudformation describe-stack-events --stack-name StreamcoLab" and watching for an event which looks like:
```
        {
            "StackId": "arn:aws:cloudformation:ap-southeast-2:954855755132:stack/StreamcoLab/6074a940-62ad-11e4-8bac-506726f6fb9a",
            "EventId": "9d4ed110-62ad-11e4-90d0-50671e35b19a",
            "ResourceStatus": "CREATE_COMPLETE",
            "ResourceType": "AWS::CloudFormation::Stack",
            "Timestamp": "2014-11-02T16:30:53.511Z",
            "StackName": "StreamcoLab",
            "PhysicalResourceId": "arn:aws:cloudformation:ap-southeast-2:954855755132:stack/StreamcoLab/6074a940-62ad-11e4-8bac-506726f6fb9a",
            "LogicalResourceId": "StreamcoLab"
        },
```
i.e "ResourceType" is "AWS::CloudFormation::Stack" and "ResourceStatus" is "CREATE_COMPLETE".
When this event exists, execute the following to get the URL to the web service:
```
aws cloudformation describe-stacks --stack-name StreamcoLab
```
and look for the "Outputs" section:
```
            "Outputs": [
                {
                    "Description": "The URL of the website",
                    "OutputKey": "URL",
                    "OutputValue": "http://StreamcoL-ElasticL-1HO1BERCE7EMK-1964054685.ap-southeast-2.elb.amazonaws.com"
                }
            ],
```
You can browse to the URL mentioned in the "OutputValue".
