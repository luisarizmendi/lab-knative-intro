#!/bin/bash


echo "****************************"
echo "Configuring Knative"
echo "****************************"

echo "Configure Serving"
cd serving/  ; chmod +x run.sh ; ./run.sh ; cd ..


echo "Configure Eventing"
cd eventing/  ; chmod +x run.sh ; ./run.sh ; cd ..
