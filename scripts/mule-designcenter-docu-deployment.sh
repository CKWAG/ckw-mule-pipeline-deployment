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
publication_state=development

echo "arguments passed:"
echo "version:       $1"
echo "name:          $2"
echo "artifactId:    $3"
echo "RAML File:     $4"
echo "GroupId:       $5"
echo "Design-Center: $8"
echo "Description:   $9"

echo "publishing state: $publication_state"


#################################################################################################
## create a bearer token and store it for later use                                            ##
#################################################################################################

muleaccesstoke=$(curl --location --request POST https://eu1.anypoint.mulesoft.com/accounts/api/v2/oauth2/token \
 --header 'Content-Type: application/x-www-form-urlencoded' \
 --data-urlencode "client_id=$6" \
 --data-urlencode "client_secret=$7" \
 --data-urlencode 'grant_type=client_credentials' --silent | jq -r ".access_token");

#################################################################################################
## GET THE GIT-PROJECT-OWNER FROM ANYPOINT DESIGN CENTER                                       ##
#################################################################################################

httpstatus=$(curl -v \
  -H "Authorization: bearer $muleaccesstoke" \
  -H "x-organization-id: $5" \
  --silent \
  --write-out %{http_code} \
  --output ./http.response.json \
  https://eu1.anypoint.mulesoft.com/designcenter/api-designer/projects/"$8");


# print the http resonse to get better debug informations if something went wrong
jq --color-output . ./http.response.json

# get x-owner-id
projectownerid=96aa6e32-8927-47d8-905b-9cf8e422001d
#$(jq --raw-output '.createdBy' http.response.json)

# print the http resonse to get better debug informations if something went wrong
jq --color-output . ./http.response.json

#################################################################################################
## UPLOAD THE RAML DOCUMENTATION INTO ANYPOINT EXCHANGE                                        ##
#################################################################################################
IFS='-'; #setting hyphen as delimiter  
read -a strarr <<<"$1"; #reading str as an array as tokens separated by IFS

assetStatus="development";

# check if SNAPSHOT is not available
if [ -z "${strarr[1]}" ];
then
      assetStatus="published";
      publication_state=published
fi

# read the main-Version
IFS='.'; #setting point as delimiter  
read -a strvers <<<"$strarr[0]"; #reading str as an array as tokens separated by IFS
mainVersion="v$strvers";

## debug output
echo "the asset will be deployed as \"$assetStatus\" and main-version \"$mainVersion\" and detail-version $strarr";

#################################################################################################
## LOCK THE DESIGN CENTER PROJECT MASTER BRANCH                                                ##
#################################################################################################
# 
httpstatus=$(curl -v \
  -H "Authorization: bearer $muleaccesstoke" \
  -H "x-organization-id: $5" \
  -H "x-owner-id: $projectownerid" \
  -X POST \
  --silent \
  --write-out %{http_code} \
  --output ./http.response.json \
  https://eu1.anypoint.mulesoft.com/designcenter/api-designer/projects/"$8"/branches/master/acquireLock);

# print the http resonse to get better debug informations if something went wrong
jq --color-output . ./http.response.json

#################################################################################################
## PUBLISH THE API RAML TO EXCHANGE AS AN ASSET                                                ##
#################################################################################################
# $projectownerid" \

publish_httpstatus=$(curl -v \
  -H "Authorization: bearer $muleaccesstoke" \
  -H "x-organization-id: $5" \
  -H "x-owner-id: $projectownerid" \
  -H "Content-Type: application/json" \
  --silent \
  --data "{\"status\":\"$publication_state\", \"name\":\"$2\", \"apiVersion\":\"$mainVersion\",\"tags\":[], \"version\":\"$strarr\", \"main\":\"$4\", \"assetId\":\"$3\", \"groupId\":\"$5\",\"classifier\":\"raml\",\"isVisual\":false,\"metadata\":{\"projectId\":\"$8\",\"branchId\":\"master\"},\"publishList\":[],\"originalFormatVersion\":\"1.0\"}" \
  --write-out %{http_code} \
  --output ./http.response.json \
  https://eu1.anypoint.mulesoft.com/designcenter/api-designer/projects/"$8"/branches/master/publish/exchange);

# print the http resonse to get better debug informations if something went wrong
jq --color-output . ./http.response.json

#################################################################################################
# UNLOCK THE DESIGN CENTER PROJECT MASTER BRANCH                                               ##
#################################################################################################
# $projectownerid" \
httpstatus=$(curl -v \
  -H "Authorization: bearer $muleaccesstoke" \
  -H "x-organization-id: $5" \
  -H "x-owner-id: $projectownerid" \
  -X POST \
  --silent \
  --write-out %{http_code} \
  --output ./http.response.json \
  https://eu1.anypoint.mulesoft.com/designcenter/api-designer/projects/"$8"/branches/master/releaseLock);

# print the http resonse to get better debug informations if something went wrong while publishing
jq --color-output . ./http.response.json

# check the http-status for errors
if [ $publish_httpstatus -lt 300 ];
then
    echo "OK, HTTP-Status $publish_httpstatus";
    exit 0;
else if [ $publish_httpstatus -eq 409 ];
then 
    echo "WARNING $publish_httpstatus - The asset was already published as Stable"
    exit 0;
else
    echo "ERROR - Asset cann't be published to Exchange, error  $publish_httpstatus "
    exit 1;
fi