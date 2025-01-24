#!/bin/bash

IP_ADDRESS_TO_FIND="3.19.73.112"            # This is the IP address you want to figure out where it belongs

#This script assumes:
# 1. You have the AWS CLI configured
# 2. You have jq installed
# 3. You have AWS Config aggregator installed and running at the organization level

export AGGREGATOR_NAME="test-agg"       #The name of the aggregator
export REGION_NAME="us-east-2"          #The region of the aggregator

json_data=$( aws configservice list-aggregate-discovered-resources --resource-type AWS::EC2::Instance --configuration-aggregator-name "${AGGREGATOR_NAME}" --region ${REGION_NAME} )

#json_data is a json array. Loop over it
echo $json_data | jq -c '.ResourceIdentifiers[]' | while read i; do
    source_account_id=$( echo $i | jq -r '.SourceAccountId' )
    source_region=$( echo $i | jq -r '.SourceRegion' )
    resource_id=$( echo $i | jq -r '.ResourceId' )
    resource_type=$( echo $i | jq -r '.ResourceType' )

    item_config=$( aws configservice get-aggregate-resource-config --configuration-aggregator-name ${AGGREGATOR_NAME} --region ${REGION_NAME} --resource-identifier $i )
    #item_config contains a string that looks like this: "publicIpAddress":"3.19.73.112"
    #Find the IP address in the string
     
    ip_address=$( echo $item_config | grep -o '\\"publicIpAddress\\":\\"[0-9,\.]*\\"' | grep -o '[0-9,.]*' )
    if [[ "$IP_ADDRESS_TO_FIND" == "$ip_address" ]]; then
        echo "Found IP address $IP_ADDRESS_TO_FIND in resource $resource_id"
        echo "Source account ID: $source_account_id"
        echo "Source region: $source_region"
        echo "Resource type: $resource_type"
        echo "IP address: $ip_address"
        echo ""
    fi
    
done
