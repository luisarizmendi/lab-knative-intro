#!/bin/bash
USERCOUNT=25

RUN_PREREQUISITES=false
MULTIUSER=false

while [[ $# -gt 0 ]] && [[ ."$1" = .--* ]] ;
do
    opt="$1";
    shift;              #expose next argument
    case "$opt" in
        "--" ) break 2;;
        "--prerequisites" )
           RUN_PREREQUISITES="true";;
        "--multiuser" )
           MULTIUSER="true";;
        *) exit 0;;
   esac
done






if [ $RUN_PREREQUISITES = true ]
then
    echo "Running pre-requisites"
    echo "**********************"
    echo ""

    echo "Configure authentication"
    cd prerequisites/authentication/  ; chmod +x run.sh ; ./run.sh ; cd ../..
    sleep 15
    oc login -u clusteradmin -p redhat

    if [ $MULTIUSER = true ]
    then
    echo "Configure NFS autoprovisioner (not supported, only for PoC)"
    cd prerequisites/nfs-autoprovisioner/  ; chmod +x run.sh ; ./run.sh ; cd ../..
    fi

    echo "Configure Service Mesh"
    cd prerequisites/service-mesh   ; chmod +x run.sh ; ./run.sh ; cd ../..


    echo "Configure Knative"
    cd prerequisites/knative   ; chmod +x run.sh ; ./run.sh ; cd ../..


    oc new-project workshop-knative-intro-content
    #oc patch servicemeshmemberrolls.maistra.io -n istio-system default --type='json' -p='[{"op": "add", "path": "/spec/members/0", "value":"workshop-knative-intro-content"}]'


fi





if [ $MULTIUSER = true ]
then
  echo "Create projects to run the workshop"

  for i in $(eval echo "{1..$USERCOUNT}") ; do
    oc new-project workshop-knative-intro-user$i > /dev/null 2>&1
    oc adm policy add-role-to-user admin user$i -n workshop-knative-intro-user$i
  done


  echo "Add projects to the Service Mesh"

  echo '#!/bin/bash' > tmp.sh
  chmod +x tmp.sh
  for i in $(eval echo "{1..$USERCOUNT}") ; do
    value="oc patch servicemeshmemberrolls.maistra.io -n istio-system default --type='json' -p='[{\"op\": \"add\", \"path\": \"/spec/members/$i\", \"value\":\"workshop-knative-intro-user$i\"}]'"
    echo $value >> tmp.sh
  done
  ./tmp.sh
  rm tmp.sh

else
  #echo "Create projects to run the workshop and adding it to Service Mesh"
  #OC_NAME=$(oc whoami)
  #oc new-project workshop-knative-intro-${OC_NAME}
  #value="oc patch servicemeshmemberrolls.maistra.io -n istio-system default --type='json' -p='[{\"op\": \"add\", \"path\": \"/spec/members/1\", \"value\":\"workshop-knative-intro-${OC_NAME}\"}]'"
  #echo $value >> tmp.sh
  #./tmp.sh
  #rm tmp.sh
  oc patch servicemeshmemberrolls.maistra.io -n istio-system default --type='json' -p='[{"op": "add", "path": "/spec/members/0", "value":"workshop-knative-intro-content"}]'
fi




echo "Building and deploying workshop"

oc project workshop-knative-intro-content


cd ..

if [ $MULTIUSER = true ]
then
  .workshop/scripts/deploy-spawner.sh
  echo "multiuser" > typedeployed
else
  .workshop/scripts/deploy-personal.sh
  echo "personal" > typedeployed
fi

sleep 5
.workshop/scripts/build-workshop.sh
oc rollout status $(oc get dc -o name)
sleep 10


WORKSHOP_URL=$(oc get routes.route.openshift.io  | grep workshop | awk '{print $2}')

echo ""
echo ""
echo "**********************************************************************************************"
echo "   Now you can open https://$WORKSHOP_URL"
echo ""
echo "   Use your OpenShift credentials to log in"
echo "**********************************************************************************************"
echo ""
