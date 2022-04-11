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

## some debug informations
echo "arguments passed:"
echo "version:       $1"
echo "name:          $2"
echo "artifactId:    $3"
echo "RAML File:     $4"
echo "GroupId:       $5"
echo "Design-Center: $8"
echo "Description:   $9"

# create a bearer token and store it for later use
muleaccesstoke=$(curl --location --request POST https://eu1.anypoint.mulesoft.com/accounts/api/v2/oauth2/token \
 --header 'Content-Type: application/x-www-form-urlencoded' \
 --data-urlencode "client_id=$6" \
 --data-urlencode "client_secret=$7" \
 --data-urlencode 'grant_type=client_credentials' --silent | jq -r ".access_token")

source scripts/mule-git-clone-design-center-project.sh "$8" "$5" "$6" "$7" "$3" "$1"
source scripts/mule-upload-raml-to-exchange.sh "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$9"