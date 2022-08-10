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