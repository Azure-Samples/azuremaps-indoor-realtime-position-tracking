//MIT License
//
//Copyright (c) Microsoft Corporation.
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE
module.exports = async function (context, myTimer) {
    // Create a GeoJSON object
    var locHistory = '{"type": "FeatureCollection","features": [';

    // Reference the Azure Strorage NPM package 
    const { BlobServiceClient } = require('@azure/storage-blob');
    
    // Read Azure Storage Connection String
    const connStr = process.env.AzureWebJobsStorage;
    // context.log('Azure Storage Connection String: ' + connStr);

    // Create a service client
    const blobServiceClient = BlobServiceClient.fromConnectionString(connStr);

    // Create a container client
    const containerClient = blobServiceClient.getContainerClient("iotclogs");
    
    // Iterate over all blobs in the container
    for await (const blob of containerClient.listBlobsFlat()) {
        context.log("Processing blob: ", blob.name);
        // Create a blob client 
        const blockBlobClient = containerClient.getBlockBlobClient(blob.name);
        // Read blob data
        const downloadBlockBlobResponse = await blockBlobClient.download(0);
        context.log("Downloaded blob content");
        const blockBlobContent = await streamToText(downloadBlockBlobResponse.readableStreamBody);
        // Process blo line by line
        var blockBlobContentLines = blockBlobContent.split("\n");
        for(const line of blockBlobContentLines) {
            if (line.length > 0){
                var blockBlobContentLineObj = JSON.parse(line);
                //locHistory = locHistory + '{"type":"Feature","geometry":{"type":"Point","coordinates":[' + blockBlobContentLineObj.telemetry.geolocation.lon + ',' + blockBlobContentLineObj.telemetry.geolocation.lat + ']},"properties":{}},'
                locHistory = locHistory + '{"type":"Feature","geometry":{"type":"Point","coordinates":[' + blockBlobContentLineObj.telemetry.GPSCoordinates.lon + ',' + blockBlobContentLineObj.telemetry.GPSCoordinates.lat + ']},"properties":{}},'
            }
        }
        context.log("Processed blob");
    }
    locHistory = locHistory.substring(0, locHistory.length-1) + ']}';
    // context.log('Created GeoJSON: ' + locHistory);

    // Write GeoJSON to blob
    var timeStamp = new Date().toISOString();
    if (myTimer.isPastDue)
    {
        context.log('Timer trigger running late!');
    }
    context.bindings.outputBlob = locHistory;
    context.log('Wrote GeoJSON to blob')
};

// Convert stream to text
async function streamToText(readable) {
    readable.setEncoding('utf8');
    let data = '';
    for await (const chunk of readable) {
      data += chunk;
    }
    return data;
}