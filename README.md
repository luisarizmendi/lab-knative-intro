LAB - Knative
=====================

Get started with your serverless journey



PREREQUISITES
=====================

This workshop needs some prerequisites to be configured in the OpenShift cluster in order to make it work:

           * Project named "workshop-knative-intro-content"
           * Knative serving and eventing support
           * Service Mesh (Istio) support (project workshop-knative-intro-content included in member roll list)

Some scripts that can fulfill those prerequisites have been included as part of the workshop files, and can be automatically provisioned if you include the --prerequisites as part of the command (by default no prerequisites are configured). Be aware that you NEED TO BE LOG IN AS CLUSTER ADMIN in order to configure those pre-requisites

If you want to run to run the prerequisites scripts include the --prerequisites option in the command, like this: launch/run.sh --prerequisites


SINGLE and MULTIUSER modes
=====================


This workshop can work in two modes: single user or multiuser. If you run it as multiuser (default is single user) you will need a dynamic persistent volume storage and run this command. If you run the prerequistes as part of this command be aware that there is a nfs-autoprovisioner module (under ./launch/prerequisites) that will be run and that will configure the unsupported NFS dynamic provisioner but, if you decide to run it, YOU WILL NEED TO PREPARE THE FILES WITH THE RIGHT NFS IP ADDRESS AND PATH.

Also take into account that, even if you don't run the prerequisites, you will NEED TO BE LOG IN AS CLUSTER ADMIN in OpenShift since multiple projects and users will be created

If you want to run the single user just not include any option, if you want multiuser add the --multiuser in the command, like this: launch/run.sh --multiuser
