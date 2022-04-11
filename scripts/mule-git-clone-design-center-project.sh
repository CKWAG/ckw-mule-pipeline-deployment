#!/bin/bash
#!/bin/bash
## curl the maven generated zip-archive into anypoint exchange, to 
## deploy a new asset or update an existing asset

## all variables must be be taken out of the POM file
## $1 = Design Center Project ID
## $2 = groupId whitch is the org-id from mulesoft anypoint
## $3 = Anypoint-ClientID
## $4 = Anypoint-ClientSecret
## $5 = artifactId
## $6 = Version out of a POM file


# clone the project to get all documentation
git -c http.extraheader="Authorization: bearer $muleaccesstoke" clone https://eu1.anypoint.mulesoft.com/git/$2/$1

# delete git folder since they are not used within the exchange documentation
rm -f $1/.gitignore
rm -rf $1/.git

# zip the documents from design center
cd $1
zip -r ../target/$5-$6-raml.zip *
cd ..

# clean-up the downloaded project from design center
rm -rf $1