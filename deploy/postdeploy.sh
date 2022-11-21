echo "Post deployment script starting..."

iothubname=$1
rgname=$2
location=$3
funcappid=$4
storagename=$5
containername=$6

echo "iot hub name: ${iothubname}"
echo "location: ${location}"
echo "funcappid: ${funcappid}"
echo "storagename: ${storagename}"
echo "containername: ${containername}"

echo "Installing azure cli extension..."
outputJSON=$(az config set extension.use_dynamic_install=yes_without_prompt)
echo $outputJSON

outputJSON=$(az extension add --name azure-iot -y)
echo $outputJSON

echo "Retrieving files..."
outputJSON=$(git clone https://github.com/Azure-Samples/azuremaps-indoor-realtime-position-tracking.git)
echo $outputJSON

echo "Retrieving and uploading public files to blob storage..."
outputJSON=$(az storage blob upload-batch --account-name $storagename -d $containername -s "./src/public")
echo $outputJSON

echo "Post deployment script completed!"