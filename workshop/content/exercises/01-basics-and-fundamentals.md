<h1>Deploy Service</h1>

Navigate to the tutorial chapter’s knative folder:

```execute
cd $TUTORIAL_HOME/02-basics/knative
```

The following snippet shows what a Knative service YAML looks like:

```copy
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: greeter
spec:
  template:
    metadata:
      name: greeter-v1
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

The service can be deployed using the following command:

```execute
oc apply -n knativetutorial -f service.yaml
```

After successful deployment of the service we should see a Kubernetes Deployment named similar to greeter-nsrbr-deployment available:

```execute
oc get deployments -n knativetutorial
```
<em> Note: The actual deployment name may vary in your setup</em>


<h1>Invoke Service</h1>

```execute
export SVC_URL=`oc get rt greeter -o yaml | yq read - 'status.url'` && http $SVC_URL
```

The http command should return a response containing a line similar to *Hi greeter ⇒ '6fee83923a9f' : 1*

<em> Note: Sometimes the response might not be returned immediately especially when the pod is coming up from dormant state. In that case, repeat service invocation.</em>


<h1>See what you have deployed</h1>

The service-based deployment strategy that we did now will create many Knative resources, the following commands will help you to query and find what has been deployed.

<h2>service</h2>

```execute
oc --namespace knativetutorial  get services.serving.knative.dev greeter
```

<h2>configuration</h2>

```execute
oc --namespace knativetutorial get configurations.serving.knative.dev greeter
```
<h2>routes</h2>

```execute
oc --namespace knativetutorial get routes.serving.knative.dev greeter
```

When the service was invoked with http `$IP_ADDRESS` 'Host:greeter.knativetutorial.example.com', you noticed that we added a Host header to the request with value `greeter.knativetutorial.example.com`. This FQDN is automatically assigned to your Knative service by the Knative Routes and uses the following format: `<service-name>.<namespace>.<domain-suffix>`.

<em> Note: The domain suffix in this case example.com is configurable via the config map config-domain of knative-serving namespace.</em>


<h2>revisions</h2>

```execute
oc --namespace knativetutorial get rev \
 --selector=serving.knative.dev/service=greeter \
 --sort-by="{.metadata.creationTimestamp}"
```


<h1>Deploy a New Revision of a Service</h1>

As Knative follows [12-Factor](https://12factor.net/) application principles, any [configuration](https://12factor.net/config) change will trigger creation of a new revision of the deployment.

To deploy a new revision of the greeter service, we will add an environment variable to the existing service as shown below:

<h2>Service revision 2</h2>

```copy
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: greeter
spec:
  template:
    metadata:
      name: greeter-v2
      annotations:
        # disable istio-proxy injection
        sidecar.istio.io/inject: "false"
    spec:
      containers:
      - image: quay.io/rhdevelopers/knative-tutorial-greeter:quarkus
        env:
        - name: MESSAGE_PREFIX
          value: Namaste
        livenessProbe:
          httpGet:
            path: /healthz
        readinessProbe:
          httpGet:
            path: /healthz
```

Adding an environment variable that will be used as the message prefix

Let us deploy the new revision using the command:

```execute
oc apply -n knativetutorial -f service-env.yaml
```

After successful deployment of the service we should see a Kubernetes deployment called `greeter-v2-deployment`.

Now if you list revisions, you will see two of them, named similar to `greeter-v1` and `greeter-v2`.


<h2>revisions</h2>

```execute
oc --namespace knativetutorial get rev \
 --selector=serving.knative.dev/service=greeter \
 --sort-by="{.metadata.creationTimestamp}"
```
Invoking Service will now show an output like *Namaste greeter ⇒ '6fee83923a9f' : 1*, where Namaste is the value we configured via environment variable in the Knative service resource file.



<h1>Pinning Service to a Revision</h1>

As you noticed, Knative service always routes traffic to the latest revision of the service deployment. It is possible to split the traffic amongst the available revisions.

As we already know the at got two revisions namely `greeter-v1` and `greeter-v2`. The `traffic` block in the Knative service specification helps in pinning a service to a particular revision or split traffic among multiple revisions.


<h2>Service pinned to first revision</h2>

```copy
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: greeter
spec:
  template:
    metadata:
      name: greeter-v2
      annotations:
        # disable istio-proxy injection
        sidecar.istio.io/inject: "false"
    spec:
      containers:
      - image: quay.io/rhdevelopers/knative-tutorial-greeter:quarkus
        env:
        - name: MESSAGE_PREFIX
          value: Namaste
        livenessProbe:
          httpGet:
            path: /healthz
        readinessProbe:
          httpGet:
            path: /healthz
  traffic:
  - tag: current
    revisionName: greeter-v1
    percent: 100
  - tag: prev
    revisionName: greeter-v2
    percent: 0
  - tag: latest
    latestRevision: true
    percent: 0
```

The above service definition creates three sub-routes(named after traffic tags) to existing `greeter` route.

<ul>
<li>current - The revision is going to have all 100% traffic distribution</li>
<li>prev - The previously active revision, which will now have zero traffic</li>
<li>latest - The route pointing to any latest service deployment, by setting to zero we are making sure the latest revision is not picked up automatically.</li>
</ul>

Let us redeploy the greeter service by pinning it to the `greeter-v1`:

```execute
oc -n knativetutorial  apply -f service-pinned.yaml
```

Let us list the available sub-routes:

```execute
oc -n knativetutorial get ksvc greeter -oyaml \
  | yq r - 'status.traffic[*].url'
```

The above command should return you three sub-routes for the main `greeter` route:

- http://current-greeter.knativetutorial.%cluster_subdomain%
- http://prev-greeter.knativetutorial.%cluster_subdomain%
- http://latest-greeter.knativetutorial.%cluster_subdomain%

<ol>
<li>the sub route for the traffic tag current</li>
<li>the sub route for the traffic tag prev</li>
<li>the sub route for the traffic tag latest</li>
</ol>


Invoking Service will produce output similar to *Hi greeter ⇒ '6fee83923a9f' : 1*

As per the current traffic distribution, the greeter route will always return response from revision `greeter-v1` (traffic tag current)


<h1>Cleanup</h1>

```execute
oc -n knativetutorial delete services.serving.knative.dev greeter
```
