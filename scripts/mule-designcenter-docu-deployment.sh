#!/bin/bash

## curl the maven generated zip-archive into anypoint exchange, to 
## deploy a new asset or update an existing asset

## all variables must be be taken out of the POM file
## $1 = Version out of a POM file
## $2 = Name of the Asset
## $3 = artifactId
## $4 = RAML File-Name
## $5 = groupId whitch is the org-id from mulesoft anypoint
## $6 = Anypoint-ClientID
## $7 = Anypoint-ClientSecret
## $8 = Design Center Project ID
## $9 = Description

#################################################################################################
## some debug informations                                                                     ##
#################################################################################################

echo "arguments passed:"
echo "version:       $1"
echo "name:          $2"
echo "artifactId:    $3"
echo "RAML File:     $4"
echo "GroupId:       $5"
echo "Design-Center: $8"
echo "Description:   $9"

#################################################################################################
## create a bearer token and store it for later use                                            ##
#################################################################################################

muleaccesstoke=$(curl --location --request POST https://eu1.anypoint.mulesoft.com/accounts/api/v2/oauth2/token \
 --header 'Content-Type: application/x-www-form-urlencoded' \
 --data-urlencode "client_id=$6" \
 --data-urlencode "client_secret=$7" \
 --data-urlencode 'grant_type=client_credentials' --silent | jq -r ".access_token")

source docu-deployment/scripts/mule-upload-raml-to-exchange.sh "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$9"

#################################################################################################
## GET THE GIT-PROJECT FROM ANYPOINT DESIGN CENTER                                             ##
#################################################################################################

# clone the project to get all documentation
git -c http.extraheader="Authorization: bearer $muleaccesstoke" clone https://eu1.anypoint.mulesoft.com/git/$5/$8

# delete git folder since they are not used within the exchange documentation
rm -f $8/.gitignore
rm -rf $8/.git

# zip the documents from design center
cd $8
zip -r ../target/$3-$1-raml.zip *
cd ..

# clean-up the downloaded project from design center
rm -rf $8

#################################################################################################
## UPLOAD THE RAML DOCUMENTATION INTO ANYPOINT EXCHANGE                                        ##
#################################################################################################
IFS='-'; #setting comma as delimiter  
read -a strarr <<<"$1"; #reading str as an array as tokens separated by IFS

assetStatus="development";

# check if SNAPSHOT is not available
if [ -z "${strarr[1]}" ];
then
      assetStatus="published";
fi

# read the main-Version
IFS='.'; #setting comma as delimiter  
read -a strvers <<<"$strarr[0]"; #reading str as an array as tokens separated by IFS
mainVersion="v$strvers";

## debug output
echo "the asset will be deployt as \"$assetStatus\" and main-version \"$mainVersion\" and detail-version $strarr";

httpstatus=$(curl -v \
  -H "Authorization: bearer $muleaccesstoke" \
  -H 'x-sync-publication: true' \
  -F "name=$2" \
  -F "description=$9" \
  -F 'type=RAML' \
  -F "status=$assetStatus" \
  -F "properties.mainFile=$4" \
  -F "properties.apiVersion=$mainVersion" \
  -F "files.raml.zip=@target/$3-$1-raml.zip" \
  --silent \
  --write-out %{http_code} \
  --output /dev/null \
  https://eu1.anypoint.mulesoft.com/exchange/api/v2/organizations/"$5"/assets/"$5"/"$3"/"$strarr");

# check the http-status for errors
if [ $httpstatus -lt 300 ];
then
    echo "OK, HTTP-Status $httpstatus";
    exit 0;
else
    echo "NOK"
    exit 1;
fi