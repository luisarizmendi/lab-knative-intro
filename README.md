LAB - Knative
=====================

Get started with your serverless journey

If you are modifying the files of this repo you will need to create a new container image, just type these commands:

    oc new-project workshop-knative

    git clone --single-branch --branch master --recurse-submodules https://github.com/luisarizmendi/lab-knative-intro.git

    cd lab-knative

    .workshop/scripts/deploy-spawner.sh --settings=develop

    .workshop/scripts/build-workshop.sh

    oc rollout status dc/lab-knative

Then you can see your modifications and you can push the used image in your registry
