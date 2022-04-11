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
## $8 = Description

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
  -F "description=$8" \
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