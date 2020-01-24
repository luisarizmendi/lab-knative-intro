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
           RUN_PREREQUISITES="true"; shift;;
        "--multiuser" )
           MULTIUSER="true"; shift;;
        *) exit 0;;
   esac
done






if [ $RUN_PREREQUISITES = true ]
then
    echo "Running pre-requisites"
    echo "**********************"
    echo ""

    echo "Configure authentication"
    cd prerequistes/authentication/  ; chmod +x run.sh ; ./run.sh ; cd ../..

    if [ $MULTIUSER = true ]
    then
    echo "Configure NFS autoprovisioner (not supported, only for PoC)"
    cd prerequistes/nfs-autoprovisioner/  ; chmod +x run.sh ; ./run.sh ; cd ../..
    fi

    echo "Configure Service Mesh"
    cd prerequistes/service-mesh   ; chmod +x run.sh ; ./run.sh ; cd ../..


    echo "Configure Knative"
    cd prerequistes/knative   ; chmod +x run.sh ; ./run.sh ; cd ../..


    oc new-project workshop-knative-intro-content
    oc patch servicemeshmemberrolls.maistra.io -n istio-system default --type='json' -p='[{\"op\": \"add\", \"path\": \"/spec/members/0\", \"value\":\"workshop-knative-intro-content\"}]'


fi





if [ $MULTIUSER = true ]
then
  echo "Create projects to run the workshop"

  for i in $(eval echo "{0..$USERCOUNT}") ; do
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

fi




echo "Building and deploying workshop"

oc project workshop-knative-intro-content


git clone --single-branch --branch master --recurse-submodules https://github.com/luisarizmendi/lab-knative-intro.git

cd lab-knative-intro

#.workshop/scripts/deploy-personal.sh
.workshop/scripts/deploy-spawner.sh

.workshop/scripts/build-workshop.sh

sleep 30
