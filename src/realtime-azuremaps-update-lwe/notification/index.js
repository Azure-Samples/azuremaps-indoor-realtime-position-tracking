module.exports = function (context, req) {
    context.log('Node.js HTTP trigger function processed a request. RequestUri=%s', req.originalUrl);

    if (req.body) {
        console.log('Request Body: ' + JSON.stringify(req.body)) ;
        //
        // sample message: 
        //{
        //    "BatteryLevel": 100,
        //    "Temperature": 19.235294,
        //    "Movement": -1,
        //    "HorizontalAccuracy": 11,
        //    "GPSCoordinates": {
        //        "lon": -122.04759188492183,
        //        "lat": 47.63018575519655,
        //        "alt": 0
        //    },
        //    "_eventtype": "Telemetry",
        //    "_timestamp": "2022-06-24T18:06:17.981Z"
        //}
        //
        context.bindings.actions = {
            "actionName": "sendToAll",
            "data": `{"DeviceID":"${req.body.deviceId}","Time":"${new Date(req.body.enqueuedTime).toLocaleString()}","Lat":${req.body.telemetry.GPSCoordinates.lat},"Lon":${req.body.telemetry.GPSCoordinates.lon}}`,
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