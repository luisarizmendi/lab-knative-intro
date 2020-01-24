<h1>Knative Service Commands</h1>

In the [previous chapter](01-basics-and-fundamentals) you created, updated and deleted the Knative service using the YAML and kubectl/oc command line tools.

We will perform the same operations in this chapter but with kn that is already installed in this system:

<h2>Create Service</h2>

To create the greeter service using kn run the following command:

```execute
kn service create greeter  --image quay.io/rhdevelopers/knative-tutorial-greeter:quarkus
```

A successful create of the greeter service should show a response like

    Service 'greeter' successfully created in namespace {{ project_namespace }}.
    Waiting for service 'greeter' to become ready ... OK

    Service URL:
    http://greeter.{{ project_namespace }}.{{ cluster_subdomain }}

<h2>List Knative Services</h2>

You can list the created services using the command:

```execute
kn service list
```

<h2>Invoke Service</h2>

You can verify what the kn client has deployed, to make sure its inline with what you have see in [previous chapter](01-basics-and-fundamentals).

```execute
export SVC_URL=`oc get rt greeter  --template '{{.status.url}}'` && http $SVC_URL
```

<h2>Update Knative Service</h2>

To create a new revision using `kn` is as easy as running another command.

In [previous chapter](01-basics-and-fundamentals) we deployed a new revision of Knative service by adding an environment variable. Lets try do the same thing with kn to trigger a new deployment:

```execute
kn service update greeter --env "MESSAGE_PREFIX=Namaste"
```

Now  invoking the service will return me a response like *Namaste greeter ⇒ '9861675f8845' : 1* (update could take some time, run the command couple of times)

```execute
http $SVC_URL
```

<h2>Describe Knative Service</h2>

Sometime you wish you get the YAML of the Knative service to build a new service or to compare with with another service. kn makes it super easy for you to get the YAML:

```execute
kn service describe greeter
```

The describe should show you an exhaustive YAML like:

```copy
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  annotations:
    serving.knative.dev/creator: minikube-user
    serving.knative.dev/lastModifier: minikube-user
  creationTimestamp: "2019-08-05T12:51:40Z"
  generation: 2
  name: greeter
  namespace: {{ project_namespace }}
  resourceVersion: "35193"
  selfLink: /apis/serving.knative.dev/v1alpha1/namespaces/{{ project_namespace }}/services/greeter
  uid: c4ee1f47-b77f-11e9-96b1-22e0f431a3ed
spec:
  template:
    metadata:
      creationTimestamp: null
    spec:
      containers:
      - env:
        - name: MESSAGE_PREFIX
          value: '''Namaste'''
        image: quay.io/rhdevelopers/knative-tutorial-greeter:quarkus
        name: user-container
        resources: {}
      timeoutSeconds: 300
  traffic:
  - latestRevision: true
    percent: 100
status:
  address:
    url: http://greeter.{{ project_namespace }}.{{ cluster_subdomain }}
  conditions:
  - lastTransitionTime: "2019-08-05T13:03:33Z"
    status: "True"
    type: ConfigurationsReady
  - lastTransitionTime: "2019-08-05T13:03:33Z"
    status: "True"
    type: Ready
  - lastTransitionTime: "2019-08-05T13:03:33Z"
    status: "True"
    type: RoutesReady
  latestCreatedRevisionName: greeter-578mv
  latestReadyRevisionName: greeter-578mv
  observedGeneration: 2
  traffic:
  - latestRevision: true
    percent: 100
    revisionName: greeter-578mv
  url: http://greeter.{{ project_namespace }}.{{ cluster_subdomain }}
```

<h2>Delete Knative Service</h2>

You can also use `kn` to delete the service that were created, to delete the service named greeter run the following command:

<em> Note: If you delete the knative service with the following command, please re-run the steps above (creation of the service and a new revision) so you can continue with the lab</em>

```execute
kn service delete greeter
```

A successful delete should show an output like

    Service 'greeter' successfully deleted in namespace {{ project_namespace }}.

Listing services you will notice that the greeter service no longer exists.

```execute
kn service list
```

<h1>Knative Revision Commands</h1>

The `kn` revision commands are used to interact with revision(s) of Knative service.

<h2>Knative Revision Commands</h2>

You can list the available revisions of a Knative service using:

```execute
kn revision list
```

The command should show a list of revisions like

    NAME            SERVICE   AGE   CONDITIONS   READY   REASON
    greeter-7cqzq   greeter   11s   4 OK / 4     True
    greeter-qctxv   greeter   56s   4 OK / 4     True


<h2>Describe Revision</h2>

To get the details about a specific revision you can use the command:

```execute
REVISION_NAME=`kn revision list | grep greeter | awk '{print $1}' | head -n 1`
kn revision describe $REVISION_NAME
```

The command should return a YAML like

```copy
apiVersion: serving.knative.dev/v1alpha1
kind: Revision
metadata:
  annotations:
    serving.knative.dev/lastPinned: "1565062128"
  creationTimestamp: "2019-08-06T03:28:42Z"
  generateName: greeter-
  generation: 1
  labels:
    serving.knative.dev/configuration: greeter
    serving.knative.dev/configurationGeneration: "2"
    serving.knative.dev/service: greeter
  name: greeter-7cqzq
  namespace: {{ project_namespace }}
  ownerReferences:
  - apiVersion: serving.knative.dev/v1alpha1
    blockOwnerDeletion: true
    controller: true
    kind: Configuration
    name: greeter
    uid: 2f89f930-b7fa-11e9-96b1-22e0f431a3ed
  resourceVersion: "40312"
  selfLink: /apis/serving.knative.dev/v1alpha1/namespaces/{{ project_namespace }}/revisions/greeter-7cqzq
  uid: 49e30221-b7fa-11e9-96b1-22e0f431a3ed
spec:
  containers:
  - env:
    - name: MESSAGE_PREFIX
      value: Namaste
    image: quay.io/rhdevelopers/knative-tutorial-greeter:quarkus
    name: user-container
    resources: {}
  timeoutSeconds: 300
status:
  conditions:
  - lastTransitionTime: "2019-08-06T03:29:51Z"
    message: The target is not receiving traffic.
    reason: NoTraffic
    severity: Info
    status: "False"
    type: Active
  - lastTransitionTime: "2019-08-06T03:28:48Z"
    status: "True"
    type: ContainerHealthy
  - lastTransitionTime: "2019-08-06T03:28:48Z"
    status: "True"
    type: Ready
  - lastTransitionTime: "2019-08-06T03:28:48Z"
    status: "True"
    type: ResourcesAvailable
  imageDigest: quay.io/rhdevelopers/knative-tutorial-greeter@sha256:767e2f4b37d29de3949c8c695d3285739829c348df1dd703479bbae6dc86aa5a
  logUrl: http://localhost:8001/api/v1/namespaces/knative-monitoring/services/kibana-logging/proxy/app/kibana#/discover?_a=(query:(match:(kubernetes.labels.knative-dev%2FrevisionUID:(query:'49e30221-b7fa-11e9-96b1-22e0f431a3ed',type:phrase))))
  observedGeneration: 1
  serviceName: greeter-7cqzq
```

<h2>Delete Revision</h2>

To delete a specific revision you can use the command:

```execute
REVISION_NAME=`kn revision list | grep greeter | awk '{print $1}' | head -n 1`
kn revision delete $REVISION_NAME
```

The command should return an output like

    Revision 'greeter-7cqzq' successfully deleted in namespace {{ project_namespace }}.

Now invoking service will return the response from revision greeter-6m45j.

```execute
http $SVC_URL
```

<h1>Knative Route Commands</h1>

The `kn` revision commands are used to interact with route(s) of Knative service.

<h2>List Routes</h2>

```execute
kn route list
```

The command should return an output like

    NAME      URL                                          AGE   CONDITIONS   TRAFFIC
    greeter   http://greeter.{{ project_namespace }}.{{ cluster_subdomain }}   10m   3 OK / 3     100% -> greeter-zd7jk

<h1>Cleanup</h1>

```execute
kn service delete greeter
```
