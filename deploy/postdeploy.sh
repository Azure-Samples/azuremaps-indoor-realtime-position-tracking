echo "Post deployment script starting...\n"

iothubname=$1
rgname=$2
location=$3
funcappid=$4
storagename=$5
containername=$6

echo "iot hub name: ${iothubname}\n"
echo "location: ${location}\n"
echo "funcappid: ${funcappid}\n"
echo "storagename: ${storagename}\n"
echo "containername: ${containername}\n"

echo "Installing azure cli extension..."
az config set extension.use_dynamic_install=yes_without_prompt
az extension add --name azure-iot -y

echo "Retrieving files..."
git clone https://github.com/Azure-Samples/azuremaps-indoor-realtime-position-tracking.git

echo "Retrieving and uploading public files to blob storage..."
az storage blob upload-batch --account-name $storagename -d $containername -s "./src/public"

echo "Post deployment script completed!\n"