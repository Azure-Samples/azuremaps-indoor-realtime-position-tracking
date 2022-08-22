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
module.exports = function (context, req) {
    context.log('Node.js HTTP trigger function processed a request. RequestUri=%s', req.originalUrl);

    if (req.body) {
        console.log('Request Body: ' + JSON.stringify(req.body)) ;
        //
        // sample message: 
        // {
        //     "deviceId": "2ijbfmawbtc",
        //     "enqueuedTime": "2022-05-22T21:25:58.577Z",
        //     "telemetry": {
        //         "geolocation": {
        //             "alt": 144.09999084472656,
        //             "lat": 47.6710354,
        //             "lon": -122.0176103
        //         }
        //     }
        // }
        //
        context.bindings.actions = {
            "actionName": "sendToAll",
            "data": `{"DeviceID":"${req.body.deviceId}","Time":"${new Date(req.body.enqueuedTime).toLocaleString()}","Lat":${req.body.telemetry.geolocation.lat},"Lon":${req.body.telemetry.geolocation.lon}}`,
            "dataType": "json"
        }

        context.res = {
            body: "Done"
        };

        context.done();
    }
    else {
        context.res = {
            status: 400,
            body: "Please pass a valid JSON object in the request body"
        };
    }
};