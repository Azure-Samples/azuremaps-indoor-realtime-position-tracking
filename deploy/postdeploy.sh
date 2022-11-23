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

echo "rgname: $rgname"
echo "storagename: ${storagename}"
echo "containername: ${containername}"
echo "storagecs: ${storagecs}"
echo "eventhubname: ${eventhubname}"
echo "azuremapskey: ${azuremapskey}"
echo "blobstoragesuffix: ${blobstoragesuffix}"
echo "iothubname: ${iothubname}"

echo "Installing azure cli extension..."
az config set extension.use_dynamic_install=yes_without_prompt
az extension add --name azure-iot -y

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
zip -r functionapp.zip *.*

echo "Deploy Function App"
az functionapp deployment source config-zip -g $rgname -n $appname --src functionapp.zip

echo "Add myPhone device to IoT Hub and get connection string"
az iot hub device-identity create -n $iothubname -d "myPhone" --ee
myDeviceConnectionString=$(az iot hub device-identity connection-string show --device-id "myPhone")
echo $myDeviceConnectionString

echo "Post deployment script completed!"