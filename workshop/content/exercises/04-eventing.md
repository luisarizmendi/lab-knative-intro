At the end of this chapter you will be able to:

<ul>
<li>What is an event source?</li>
<li>What is a channel?</li>
<li>What is a subscriber?</li>
<li>What is a trigger?</li>
<li>What is a broker?</li>
<li>How to make a Knative serving service receive an event?</li>
<li>How to make a service a subscriber of an event?</li>
</ul>

<h2>Watching Logs</h2>

In the eventing related subsections of this tutorial, event sources are configured to emit events every minute with a `CronJobSource` or with a `ContainerSource`.

The logs could be watched using the command:

`oc logs  -f <pod-name> -c user-container`

<em>Note: You can use the command stern  event-greeter, to filter the logs further add -c user-container to the stern command.</em>

The logs will have the output like below printing every minute.

    INFO  [com.red.dev.dem.GreetingService] (XNIO-1 task-1) Event Message Received
    event-greeter-g94kp-deployment-89f66cb58-wjl2v user-container  {
    event-greeter-g94kp-deployment-89f66cb58-wjl2v user-container   "message" : "Thanks for doing Knative Tutorial",
    event-greeter-g94kp-deployment-89f66cb58-wjl2v user-container   "host" : "Event  greeter => 'event-greeter-5cbh5-pod-52d8fb' : 1",
    event-greeter-g94kp-deployment-89f66cb58-wjl2v user-container   "time" : "13:50:07"
    event-greeter-g94kp-deployment-89f66cb58-wjl2v user-container }

(OR)

    INFO  [com.red.dev.dem.GreetingService] (XNIO-1 task-1) Event Message Received
    event-greeter-g94kp-deployment-89f66cb58-wjl2v user-container  {
    event-greeter-g94kp-deployment-89f66cb58-wjl2v user-container   "message" : "Thanks for doing Knative Tutorial",
    event-greeter-g94kp-deployment-89f66cb58-wjl2v user-container   "host" : "Event  greeter => 'event-greeter-5cbh5-pod-52d8fb' : 2",
    event-greeter-g94kp-deployment-89f66cb58-wjl2v user-container   "time" : "13:51:00"
    event-greeter-g94kp-deployment-89f66cb58-wjl2v user-container }

<h1>Source to Service</h1>

<h2>Event Source</h2>

The event source listens to external events e.g. a kafka topic or for a file on a FTP server. It is responsible to drain the received event(s) along with its data to a configured [sink](https://en.wikipedia.org/wiki/Sink_(computing).

Navigate to the tutorial chapter’s `knative` folder:

```execute
cd $TUTORIAL_HOME/05-eventing/knative
```

<h3>Create Event Source</h3>

```copy
apiVersion: sources.eventing.knative.dev/v1alpha1
kind: CronJobSource
metadata:
  name: event-greeter-cronjob-source
spec:
  schedule: "* * * * *"
  data: '{"message": "Thanks for doing Knative Tutorial"}'
  sink:
    apiVersion: serving.knative.dev/v1alpha1
    kind: Service
    name: event-greeter
```

<ul>
<li>`kind`: The type of event source, the eventing system deploys a bunch of sources out of the box and it also provides way to deploy custom resources</li>
<li>`spec.sink`: The service(sink) where the event data will be sent</li>
</ul>


<em>Note: Event Source can define the attributes that it wishes to receive via the spec. In the above example it defines schedule(the cron expression) and data that will be sent as part of the event.

When you watch logs, you will notice this data being delivered to the service.</em>

Run the following commands to create the event source resources:

```execute
oc apply  -f event-source-svc.yaml
```

<h3>Verification</h3>
Wait until is "Ready"

```execute
oc  get cronjobsources.sources.eventing.knative.dev
```

Running the above command should return the following result:

    NAME                       AGE
    event-greeter-cronjob-source  39s

The cronjob source also creates a service pod,

```execute
oc  get pods
```

The above command will return an output like,

    NAME                                                          READY     STATUS    RESTARTS   AGE
    cronjob-event-greeter-cronjob-source-4v9vq-6bff96b58f-tgrhj   2/2       Running   0          6m

<h2>Create Sink Service</h2>

<h3>Generate Sink Service</h3>

Run the following command to create the Knative service that will be used as the subscriber for the cron events:

```copy
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: event-greeter
spec:
  template:
    metadata:
      name: event-greeter-v1
      annotations:
        # disable istio-proxy injection
        sidecar.istio.io/inject: "false"
    spec:
      containers:
      - image: quay.io/rhdevelopers/knative-tutorial-greeter:quarkus
        livenessProbe:
          httpGet:
            path: /healthz
        readinessProbe:
          httpGet:
            path: /healthz
```


<h3>Deploy Sink Service</h3>

Run the following commands to create the service:

```execute
oc apply  -f service.yaml
```

You can watch logs to see the cron job source sending an event every 1 minute.

<h3>See what you have deployed</h3>

<h4>sources</h4>

```execute
oc  get cronjobsources.sources.eventing.knative.dev event-greeter-cronjob-source
```

<h4>services</h4>

```execute
kubectl   get services.serving.knative.dev event-greeter
```

<h2>Cleanup</h2>

```execute
oc  delete services.serving.knative.dev event-greeter
oc  delete cronjobsources.sources.eventing.knative.dev  event-greeter-cronjob-source
```

<h1>Source to Subscriber</h1>

<h2>Channel(Sink)</h2>

The [channel or sink](https://en.wikipedia.org/wiki/Event-driven_architecture#Event_channel) is an interface between the [event source](https://redhat-developer-demos.github.io/knative-tutorial/knative-tutorial-basics/0.7.x/05-eventing/eventing-src-sub.html#eventing-source) and the [subscriber](https://redhat-developer-demos.github.io/knative-tutorial/knative-tutorial-basics/0.7.x/05-eventing/eventing-src-sub.html#eventing-subscriber). The channels are built in to store the incoming events and distribute the event data to the subscribers. When forwarding event to subscribers the channel transforms the event data as per [CloudEvent](http://cloudevents.io/) specification.

<h3>Create Event Channel</h3>

```copy
apiVersion: eventing.knative.dev/v1alpha1
kind: Channel
metadata:
  name: ch-event-greeter
spec:
  provisioner:
    apiVersion: eventing.knative.dev/v1alpha1
    kind: ClusterChannelProvisioner
    name: in-memory
```

<ul>
<li>`metadata.name`: The name of the channel. Knative makes it addressable, i.e. resolveable to a target (a consumer service)</li>
<li>`spec.provisioner`: The channel provisioner which is responsible for provisioning this channel. Various messaging implementations provide their own channel(s) via ClusterChannelProvisioner.</li>
</ul>

Navigate to the tutorial chapter’s `knative` folder:

```execute
cd $TUTORIAL_HOME/05-eventing/knative
```

Run the following commands to create the channel:

```execute
oc apply  -f channel.yaml
```

<h4>Verification</h4>

```execute
oc  get channels.eventing.knative.dev
```

Running the above command should return the following result:

    NAME                       AGE
    ch-event-greeter   39s

<h2>Event Source</h2>

The event source listens to external events e.g. a kafka topic or for a file on a FTP server. It is responsible to drain the received event(s) along with its data to a configured [sink](https://en.wikipedia.org/wiki/Sink_(computing).

<h3>Create Event Source</h3>

```copy
apiVersion: sources.eventing.knative.dev/v1alpha1
kind: CronJobSource
metadata:
  name: event-greeter-cronjob-source
spec:
  schedule: "* * * * *"
  data: '{"message": "Thanks for doing Knative Tutorial"}'
  sink:
    apiVersion: eventing.knative.dev/v1alpha1
    kind: Channel
    name: ch-event-greeter
```

<ul>
<li>`kind`: The type of event source, the eventing system deploys a bunch of sources out of the box and it also provides way to deploy custom resources</li>
<li>`spec.sink`: 	The channel(sink) where the event data will be drained</li>
</ul>

<em>Note: Event Source can define the attributes that it wishes to receive via the spec. In the above example it defines schedule(the cron expression) and data that will be sent as part of the event.

When you watch logs, you will notice this data being delivered to the service.</em>

Run the following commands to create the event source resources:

```execute
oc apply  -f event-source.yaml
```

<h4>Verification</h4>

```execute
oc  get cronjobsources.sources.eventing.knative.dev
```

Running the above command should return the following result:

  NAME                       AGE
  event-greeter-cronjob-source  39s

The cronjob source also creates a service pod:

```execute
oc  get pods
```

The above command will return an output like:

  NAME                                                          READY     STATUS    RESTARTS   AGE
  cronjob-event-greeter-cronjob-source-4v9vq-6bff96b58f-tgrhj   2/2       Running   0          6m

<h2>Event Subscriber</h2>

The event subscription is responsible of connecting the channel(sink) with the service. Once a service connected to a channel it starts receiving the events (cloud events).

<h3>Create Channel Subscriber</h3>

```copy
apiVersion: eventing.knative.dev/v1alpha1
kind: Subscription
metadata:
  name: event-greeter-subscriber
spec:
  channel:
    apiVersion: eventing.knative.dev/v1alpha1
    kind: Channel
    name: ch-event-greeter
  subscriber:
    ref:
      apiVersion: serving.knative.dev/v1alpha1
      kind: Service
      name: event-greeter
```

Run the following commands to create the channel subscriber:

```execute
oc apply  -f channel-subscriber.yaml
```


<h4>Verification</h4>

```execute
oc  get subscriptions.eventing.knative.dev
```

Running the above command should return the following result:

  NAME                       AGE
  event-greeter-subscriber  39s


<h2>See what you have deployed</h2>

<h3>channel</h3>

```execute
oc  get channels.eventing.knative.dev ch-event-greeter
```

<h3>sources</h3>

```execute
oc  get cronjobsources.sources.eventing.knative.dev event-greeter-cronjob-source
```

<h3>subscription</h3>

```execute
oc  get subscriptions.eventing.knative.dev event-greeter-subscriber
```


<h2>Create subscriber Service</h2>
<h3>Generate Subscriber Service</h3>

Run the following command to create the Knative service that will be used as the subscriber for the cron events:

```copy
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: event-greeter
spec:
  template:
    metadata:
      name: event-greeter-v1
      annotations:
        # disable istio-proxy injection
        sidecar.istio.io/inject: "false"
    spec:
      containers:
      - image: quay.io/rhdevelopers/knative-tutorial-greeter:quarkus
        livenessProbe:
          httpGet:
            path: /healthz
        readinessProbe:
          httpGet:
            path: /healthz
```

<h3>Deploy Subscriber Service</h3>

Run the following commands to create the service:

```execute
oc apply  -f service.yaml
```

You can watch logs to see the cron job source sending an event every 1 minute.

<h3>Cleanup</h3>

```execute
oc  delete services.serving.knative.dev event-greeter
oc  delete cronjobsources.sources.eventing.knative.dev  event-greeter-cronjob-source
oc  delete channels.eventing.knative.dev ch-event-greeter
oc  delete subscriptions.eventing.knative.dev event-greeter-subscriber
```

<h1>Triggers and Brokers</h1>

With Knative 0.5.0, Broker and Trigger objects are introduced to make event filtering easier.

Brokers provide selection of events by attributes. They receive events and forwards them to subscribers defined by matching Triggers.

Triggers provide a way of filtering of events by attributes. They are attached to subscribers and make the subscribers receive the events only they are interested in.

Navigate to the tutorial chapter’s knative folder:

```execute
cd $TUTORIAL_HOME/05-eventing/knative
```

<h2>Broker</h2>

First of all, we need to create a Broker. Knative eventing provides a Broker named `default` when a special label is added to a namespace.

```execute
oc label namespace  $(oc project | awk -F \" '{print $2}') knative-eventing-injection=enabled
```

This will create the `default` broker. Execute the following command to see it:

```execute
oc  get brokers.eventing.knative.dev
```

Output should be similar to below:

    NAME      READY     REASON    HOSTNAME                                           AGE
    default   True                default-broker.{{ project_namespace }}.svc.cluster.local   2m

Labeling the namespace will also create some pods that are related to the `default` broker.

```execute
oc  get pods
```

Running the above command should return the following result:

    NAME                                      READY     STATUS    RESTARTS   AGE
    default-broker-filter-5bb94d8ddf-r9j4v    2/2       Running   1          2m43s
    default-broker-ingress-59b9b4985c-8n6d4   2/2       Running   1          2m43s

<h2>Service</h2>
<h3>Generate Service</h3>

Run the following command to create the Knative service that will be used as the subscriber for the events that are going to be published later:

```copy
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: event-greeter
spec:
  template:
    metadata:
      name: event-greeter-v1
      annotations:
        # disable istio-proxy injection
        sidecar.istio.io/inject: "false"
    spec:
      containers:
      - image: quay.io/rhdevelopers/knative-tutorial-greeter:quarkus
        livenessProbe:
          httpGet:
            path: /healthz
        readinessProbe:
          httpGet:
            path: /healthz
```

<h3>Deploy Service</h3>

Run the following commands to create the service:

```execute
oc apply  -f service.yaml
```

<h2>Event Source</h2>

```copy
apiVersion: sources.eventing.knative.dev/v1alpha1
kind: ContainerSource
metadata:
  name: heartbeat-event-source
spec:
  image: quay.io/openshift-knative/knative-eventing-sources-heartbeats:v0.5.0
  args:
    - '--label="Thanks for doing Knative Tutorial"'
    - '--period=1'
  env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
  sink:
    apiVersion: eventing.knative.dev/v1alpha1
    kind: Broker
    name: default
```

<ul>
<li>`kind`: The type of event source. ContainerSource type is basically a container sending events.</li>
<li>`spec.image`: The image to run with this ContainerSource. Source of the image is available [here](https://github.com/knative/eventing-sources/blob/v0.5.0/cmd/heartbeats/main.go).</li>
<li>`spec.args`: 	Arguments for the ContainerSource image. label in this particular case is what the image will be sending as event data and period is how often it will send events.</li>
<li>`spec.sink`: 	Sink here is the default broker created earlier. So, the default broker will receive the events sent by this event source.</li>
</ul>

Run the following commands to create the event source resources:

```execute
oc apply  -f event-source-broker.yaml
```

<h2>Trigger</h2>

```copy
apiVersion: eventing.knative.dev/v1alpha1
kind: Trigger
metadata:
  name: event-greeter-trigger
spec:
  filter:
    sourceAndType:
      type: dev.knative.eventing.samples.heartbeat
  subscriber:
    ref:
      apiVersion: serving.knative.dev/v1alpha1
      kind: Service
      name: event-greeter
```
<ul>
<li>`spec.filter.type`:	The event type to filter on. The event type dev.knative.eventing.samples.heartbeat is the one used by the ContainerSource image we deployed earlier.</li>
<li>`spec.subscriber`: Definition of the subscriber for the events that are matched by the filter of the trigger.</li>
<li>`spec.subscriber.ref.kind`: 	In this case, the subscriber is a service.</li>
<li>`spec.subscriber.ref.name`: 	Subscriber service name. This trigger will make sure the events filtered will be sent to this service.</li>
</ul>

Run the following commands to create the event source resources:

```execute
oc apply  -f trigger.yaml
```

<h2>Verification</h2>

<h3>Logs</h3>

When you watch logs, you will notice this data being delivered to the service.

<h3>See what you have deployed</h3>
<h4>sources</h4>

```execute
oc  get containersources.sources.eventing.knative.dev heartbeat-event-source
```

<h4>services</h4>

```execute
# get a Knative Service (short name ksvc) called greeter
oc   get services.serving.knative.dev event-greeter
```

<h4>triggers</h4>

```execute
oc   get triggers.eventing.knative.dev event-greeter-trigger
```

<h2>Cleanup</h2>

```execute
oc  delete services.serving.knative.dev event-greeter
oc  delete containersource.sources.eventing.knative.dev heartbeat-event-source
oc  delete triggers.eventing.knative.dev event-greeter-trigger
oc  delete brokers.eventing.knative.dev default
```
