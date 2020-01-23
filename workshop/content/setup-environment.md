Before we start setting up the environment, let’s export the tutorial path configuring the TUTORIAL_HOME environment variable to point to the root directory of the tutorial:

```execute
export TUTORIAL_HOME="$(pwd)/knative-tutorial"
```

<em>Note: Did you type the command in yourself? If you did, click on the command instead and you will find that it is executed for you. You can click on any command which has the <span class="fas fa-play-circle"></span> icon shown to the right of it, and it will be copied to the interactive terminal and run. If you would rather make a copy of the command so you can paste it to another window, hold down the shift key when you click on the command.

Regarding the Console tab, remember to change to your project since default project could be cached, in that case you will find a lot of "forbidden access" messages.</em>

Knative should be already installed in this environment. If you are interested in installation steps you can check the [Openshift Docs](https://docs.openshift.com/container-platform/4.2/serverless/installing-openshift-serverless.html)
