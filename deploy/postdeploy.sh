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
echo $PWD

# echo 'installing azure cli extension'
#az config set extension.use_dynamic_install=yes_without_prompt
#az extension add --name azure-iot -y

# echo 'retrieve files'
#git clone https://github.com/Azure-Samples/azuremaps-indoor-realtime-position-tracking.git

# Retrieve and Upload models to blob storage
#az storage blob upload-batch --account-name $storagename -d $containername -s "./src/public"

echo "Post deployment script completed!"