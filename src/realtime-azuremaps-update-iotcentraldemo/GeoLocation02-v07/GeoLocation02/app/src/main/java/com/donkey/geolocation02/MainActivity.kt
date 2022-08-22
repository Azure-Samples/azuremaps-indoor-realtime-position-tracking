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
package com.donkey.geolocation02

import android.Manifest
import android.icu.text.SimpleDateFormat
import android.location.Location
import android.os.Bundle
import android.os.Environment
import android.os.Environment.getExternalStoragePublicDirectory
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.azure.android.maps.control.AzureMap
import com.azure.android.maps.control.AzureMaps
import com.azure.android.maps.control.MapControl
import com.azure.android.maps.control.layer.BubbleLayer
import com.azure.android.maps.control.options.BubbleLayerOptions.*
import com.azure.android.maps.control.options.CameraOptions.center
import com.azure.android.maps.control.source.DataSource
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationResult
import com.mapbox.geojson.Feature
import com.mapbox.geojson.Point
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.*


class MainActivity : AppCompatActivity() {

    private lateinit var tvStatus : TextView
    private lateinit var tvCounter : TextView
    private lateinit var tvTime : TextView
    private lateinit var tvDistance : TextView
    private lateinit var tvLat : TextView
    private lateinit var tvLon : TextView
    private lateinit var tvAlt : TextView
    private lateinit var tvBearing : TextView
    private lateinit var tvSpeed : TextView
    private lateinit var btnStartTracking : Button
    private lateinit var btnStopTracking : Button
    private val permissionsRequestCode = 123
    private lateinit var locationManager : GeoLocationManager
    private lateinit var managePermissions : PermissionManager
    private var locationTrackingRequested = false
    private var filename = ""
    private lateinit var file : File
    private lateinit var fileOutputStream : FileOutputStream
    private var counter = 0
    private val dataSource = DataSource()
    private lateinit var lastLoc : Location
    private var totalDist = 0.0f;
    private var startTime = 0L;

    companion object {
        init {
            AzureMaps.setSubscriptionKey("vvBfY2hoz84IYBdrb1meG1ImEjwAbArO0UmSzpFX48U")
        }
    }

    private val mapControl by lazy {
        findViewById<MapControl>(R.id.mapcontrol)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Create GeoLocationManager
        locationManager = GeoLocationManager(this)

        btnStartTracking = findViewById(R.id.btnStartTracking)
        btnStopTracking = findViewById(R.id.btnStopTracking)
        tvStatus = findViewById(R.id.tvStatus)
        tvTime = findViewById(R.id.tvTime)
        tvDistance = findViewById(R.id.tvDistance)
        tvCounter = findViewById(R.id.tvCounter)
        tvLat = findViewById(R.id.tvLat)
        tvLon = findViewById(R.id.tvLon)
        tvAlt = findViewById(R.id.tvAlt)
        tvBearing = findViewById(R.id.tvBearing)
        tvSpeed = findViewById(R.id.tvSpeed)
        mapControl.onCreate(savedInstanceState)

        //Wait until the map resources are ready.
        mapControl.onReady { map: AzureMap ->
            //Create a data source and add it to the map.
            map.sources.add(dataSource)

            //Create a bubble layer to render the filled in area of the circle, and add it to the map.
            val layer = BubbleLayer(
                dataSource,
                bubbleRadius(5f),
                bubbleColor("#4288f7"),
                bubbleStrokeColor("#4288f7"),
                bubbleStrokeWidth(1f)
            )
            // Add the layer to the map
            map.layers.add(layer)
        }

        btnStopTracking.isEnabled = false

        // Initialize a list of required permissions to request runtime
        val list = listOf(
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        )

        // Initialize a new instance of ManagePermissions class
        managePermissions = PermissionManager(this,list,permissionsRequestCode)

        btnStartTracking.setOnClickListener {
            managePermissions.checkPermissions()

            val dtFormat = SimpleDateFormat("yyMMdd_HHmmss", Locale.US)
            filename = "geolog_" + dtFormat.format(Date()) + ".csv"

            file = File(
                getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS),
                filename
            )

            try {
                fileOutputStream = FileOutputStream(file)
                fileOutputStream.write(("DateTime, Lat, Lon, Alt, Bearing, Speed\r\n").toByteArray())

            } catch (e: IOException) {
                e.printStackTrace()
            }

            locationManager.startLocationTracking(locationCallback)
            locationTrackingRequested = true
            tvStatus.text = getString(R.string.txtStarted)
            tvTime.text = "00:00:00"
            tvDistance.text = "0.000"

            btnStopTracking.isEnabled = true
            btnStartTracking.isEnabled = false
        }

        btnStopTracking.setOnClickListener {
            locationManager.stopLocationTracking()
            locationTrackingRequested = false
            tvStatus.text = getString(R.string.txtStopped)
            fileOutputStream.close()

            btnStopTracking.isEnabled = false
            btnStartTracking.isEnabled = true
        }
    }

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(locationResult : LocationResult) {
            for (location in locationResult .locations){
                // Update UI
                counter += 1
                tvCounter.text = counter.toString()

                // Calculate the distance
                if (counter == 1) {
                    startTime = location.time
                }
                else {
                    var elapsedTime = (location.time - startTime) / 1000
                    var hours = elapsedTime / 3600;
                    var minutes = (elapsedTime % 3600) / 60;
                    var seconds = elapsedTime % 60;
                    tvTime.text = String.format("%02d:%02d:%02d", hours, minutes, seconds)

                    var thisDist = lastLoc.distanceTo(location)
                    totalDist += thisDist
                    tvDistance.text = String.format("%.3f", totalDist / 1000)
                }
                lastLoc = location

                val date = Date(location.time)
//                tvTime.text = date.toString()

                tvLat.text = String.format("%.5f", location.latitude)
                tvLon.text = String.format("%.5f", location.longitude)
                tvAlt.text = location.altitude.toInt().toString()
                tvBearing.text = location.bearing.toInt().toString()
                tvSpeed.text = (location.speed * 3.6).toInt().toString()

                // Write Log
                fileOutputStream.write((date.toString() + ", " + location.latitude.toString() + ", " + location.longitude.toString() + ", " + location.altitude.toInt().toString() + ", " + location.bearing.toInt().toString() + ", " + (location.speed * 2.23693629).toInt().toString() + "\r\n").toByteArray())

                // Update the map
                mapControl.getMapAsync { map ->
                    //Create a feature and add it to the data source.
                    var thisPoint = Point.fromLngLat(location.longitude, location.latitude)
                    val thisFeature = Feature.fromGeometry(thisPoint)
                    dataSource.add(thisFeature)

                    //Set the camera of the map.
                    map.setCamera(center(thisPoint))
                }
            }
        }
    }

    public override fun onStart() {
        super.onStart()
        mapControl?.onStart()
    }

    public override fun onResume() {
        super.onResume()
        mapControl?.onResume()
    }

    public override fun onPause() {
        mapControl?.onPause()
        super.onPause()
    }

    public override fun onStop() {
        mapControl?.onStop()
        super.onStop()
    }

    override fun onLowMemory() {
        mapControl?.onLowMemory()
        super.onLowMemory()
    }

    override fun onDestroy() {
        mapControl?.onDestroy()
        super.onDestroy()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        mapControl?.onSaveInstanceState(outState)
    }
}