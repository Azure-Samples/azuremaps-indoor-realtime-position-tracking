echo "Post deployment script starting..."

iothubname=$1
rgname=$2
location=$3
funcappid=$4
storagename=$5
containername=$6
storagecs=$7
eventhubname=$8
azuremapskey=$9
blobstorageurl=$10

echo "iot hub name: ${iothubname}"
echo "location: ${location}"
echo "funcappid: ${funcappid}"
echo "storagename: ${storagename}"
echo "containername: ${containername}"
echo "storagecs: ${storagecs}"
echo "eventhubname: ${eventhubname}"
echo "azuremapskey: ${azuremapskey}"
echo "blobstorageurl: ${blobstorageurl}"

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
sed -i "s/<YOUR-BLOB-STORAGE-URL>/$blobstorageurl/g" "./azuremaps-indoor-realtime-position-tracking/src/realtime-azuremaps-update-iothubdemo/AzM_Web_PubSub_Demo-v02/AzM_Web_PubSub_Demo/index.html"

echo "Retrieving and uploading public files to blob storage..."
#az storage blob upload-batch --connection-string $storagecs --account-name $storagename -d $containername -s "./azuremaps-indoor-realtime-position-tracking/src/public"

echo "Post deployment script completed!"