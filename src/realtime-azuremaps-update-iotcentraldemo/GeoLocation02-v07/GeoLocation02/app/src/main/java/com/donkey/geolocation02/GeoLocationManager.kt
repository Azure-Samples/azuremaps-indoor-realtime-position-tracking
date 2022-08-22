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

import android.content.Context
import android.os.Looper
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices

class GeoLocationManager(private val context: Context) {
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    private var locationRequest= LocationRequest.create()
    private var startedLocationTracking = false
    init {
        configureLocationRequest()
        setupLocationProviderClient()
    }
    private fun setupLocationProviderClient() {
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)
    }
    private fun configureLocationRequest() {
        locationRequest.interval = UPDATE_INTERVAL_MILLISECONDS
        locationRequest.fastestInterval = FASTEST_UPDATE_INTERVAL_MILLISECONDS
        locationRequest.priority = LocationRequest.PRIORITY_HIGH_ACCURACY
    }
    fun startLocationTracking(locationCallback: LocationCallback) {
        if (!startedLocationTracking) {
            //noinspection MissingPermission
            fusedLocationClient.requestLocationUpdates(locationRequest,
                locationCallback,
                Looper.getMainLooper())
            this.locationCallback = locationCallback
            startedLocationTracking = true
        }
    }
    fun stopLocationTracking() {
        if (startedLocationTracking) {
            fusedLocationClient.removeLocationUpdates(locationCallback)
        }
    }
    companion object {
        const val UPDATE_INTERVAL_MILLISECONDS: Long = 10000
        const val FASTEST_UPDATE_INTERVAL_MILLISECONDS = UPDATE_INTERVAL_MILLISECONDS / 2
    }
}