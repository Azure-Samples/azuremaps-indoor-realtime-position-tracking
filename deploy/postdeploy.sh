echo "Post deployment script starting..."

appname=$1
rgname=$2
storagename=$3
containername=$4
storagecs=$5
eventhubname=$6
azuremapskey=$7
blobstoragesuffix=$8
iothubname=$9
devicename=${10}

echo "appname: ${appname}"
echo "rgname: ${rgname}"
echo "storagename: ${storagename}"
echo "containername: ${containername}"
echo "storagecs: ${storagecs}"
echo "eventhubname: ${eventhubname}"
echo "azuremapskey: ${azuremapskey}"
echo "blobstoragesuffix: ${blobstoragesuffix}"
echo "iothubname: ${iothubname}"
echo "devicename: ${devicename}"

echo "Installing azure cli extension..."
az config set extension.use_dynamic_install=yes_without_prompt
az extension add --name azure-iot -y

echo "Enabling remote build"
az functionapp config appsettings set -g $rgname -n $appname --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true

echo "Retrieving files..."
git clone https://github.com/Azure-Samples/azuremaps-indoor-realtime-position-tracking.git

echo "Update event hub name binding for notification function"
sed -i "s/<YOUR-EVENT-HUB-NAME>/$eventhubname/g" "./azuremaps-indoor-realtime-position-tracking/src/realtime-azuremaps-update-iothubdemo/AzM_Web_PubSub_Demo-v02/AzM_Web_PubSub_Demo/notification/function.json"

echo "Update Azure Maps key in index.html"
sed -i "s/<YOUR-AZURE-MAPS-KEY>/$azuremapskey/g" "./azuremaps-indoor-realtime-position-tracking/src/realtime-azuremaps-update-iothubdemo/AzM_Web_PubSub_Demo-v02/AzM_Web_PubSub_Demo/index.html"

echo "Update blob storage URL in index.html"
sed -i "s/<YOUR-BLOB-STORAGE-URL>/https:\/\/$storagename.blob.$blobstoragesuffix/g" "./azuremaps-indoor-realtime-position-tracking/src/realtime-azuremaps-update-iothubdemo/AzM_Web_PubSub_Demo-v02/AzM_Web_PubSub_Demo/index.html"

echo "Retrieving and uploading public files to blob storage..."
az storage blob upload-batch --connection-string $storagecs --account-name $storagename -d $containername -s "./azuremaps-indoor-realtime-position-tracking/src/public"

echo "Create zip file for Function App deployment"
cd ./azuremaps-indoor-realtime-position-tracking/src/realtime-azuremaps-update-iothubdemo/AzM_Web_PubSub_Demo-v02/AzM_Web_PubSub_Demo
zip -r functionapp.zip *.* index negotiate notification processdata

echo "Deploy Function App"
az functionapp deployment source config-zip -g $rgname -n $appname --src functionapp.zip

echo "Add myPhone device to IoT Hub"
az iot hub device-identity create --hub-name $iothubname --device-id $devicename --resource-group $rgname

deviceConnectionString=$(az iot hub device-identity connection-string show --hub-name $iothubname --device-id $devicename --resource-group $rgname)
echo "Device ${devicename} connection string: ${deviceConnectionString}"

webAppUrl=$(az functionapp function show --resource-group $rgname --name $appname --function-name index --query "invokeUrlTemplate")
echo "Web app URL: ${webAppUrl}"
outputs="{ \"outputs\": [ {\"webAppUrl\": ${webAppUrl}}, ${deviceConnectionString} ] }"
echo $outputs > $AZ_SCRIPTS_OUTPUT_PATH

echo "Post deployment script completed!"