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
using Microsoft.Azure.Devices.Client;
using Microsoft.Azure.Devices.Provisioning.Client;
using Microsoft.Azure.Devices.Provisioning.Client.Transport;
using Microsoft.Azure.Devices.Shared;
using System;
using System.Net.Mail;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace IoT_Central_Device_Sim_02
{
    internal class Program
    {
        public static async Task Main(string[] args)
        {
            //string deviceID = "your IoT Central device ID";
            string deviceID = args[0];
            Console.WriteLine("Device ID: " + args[0]);
            //string devicePK = "your IoT Central device primary key";
            string devicePK = args[1];
            Console.WriteLine("SAS Token: " + args[1]);
            //string deviceIdScope = "your device if scope";
            string deviceIdScope = args[2];
            Console.WriteLine("Device ID Scope: " + args[2]);
            string deviceDPS = "global.azure-devices-provisioning.net";
            int counter = 0;
            //string fToReplay = @"C:\Users\...\Downloads\geolog_220610081526.csv";
            string fToReplay = args[3];
            Console.WriteLine("Replaying log-file: " + args[3]);
            //int interval = 1000;
            int interval = Convert.ToInt32(args[4]) * 1000;
            Console.WriteLine("Replay 1nterval in seconds: " + args[4]);


            using DeviceClient deviceClient = await SetupDeviceClientAsync(deviceID, deviceIdScope, devicePK, deviceDPS);
            foreach (string line in System.IO.File.ReadLines(fToReplay))
            {
                if (counter == 0)
                {
                    Console.WriteLine("Beginning Replay with {0} seconds interval.", interval / 1000);
                }
                else
                {
                    string[] telemetryArray = line.Split(',');
                    string dateTime = telemetryArray[0].Trim();
                    string lat = telemetryArray[1].Trim();
                    string lon = telemetryArray[2].Trim();
                    string alt = telemetryArray[3].Trim();

                    await SendTelemetryAsync(deviceClient, lat, lon, alt, counter);
                }
                counter++;
                Thread.Sleep(interval);
            }
            await deviceClient.CloseAsync();
            Console.WriteLine("Replay complete. Press any key to exit.");
            Console.ReadLine();
        }

        private static async Task SendTelemetryAsync(DeviceClient deviceClient, string lat, string lon, string alt, int counter)
        {
            using Message msg = new Message(Encoding.UTF8.GetBytes("{\"geolocation\": {\"lat\": " + lat + ", \"lon\": " + lon + ", \"alt\": 0.0}"))
            {
                ContentEncoding = "utf-8",
                ContentType = "application'json",
            };
            msg.ComponentName = "sensors";

            await deviceClient.SendEventAsync(msg);
            Console.WriteLine("Telemetry item " + counter.ToString() + " sent - {\"geolocation\": {\"lat\": " + lat + ", \"lon\": " + lon + ", \"alt\": " + alt + "}");
        }

        private static async Task<DeviceRegistrationResult> ProvisionDeviceAsync(string deviceID, string deviceIdScope, string devicePK, string deviceDPS)
        {
            SecurityProvider symmetricKeyProvider = new SecurityProviderSymmetricKey(deviceID, devicePK, null);
            ProvisioningTransportHandler mqttTransportHandler = new ProvisioningTransportHandlerMqtt();
            ProvisioningDeviceClient pdc = ProvisioningDeviceClient.Create(deviceDPS, deviceIdScope, symmetricKeyProvider, mqttTransportHandler);
            return await pdc.RegisterAsync();
        }

        private static async Task<DeviceClient> SetupDeviceClientAsync(string deviceID, string deviceIdScope, string devicePK, string deviceDPS)
        {
            DeviceClient deviceClient;
            DeviceRegistrationResult dpsRegistrationResult = await ProvisionDeviceAsync(deviceID, deviceIdScope, devicePK, deviceDPS);
            var authMethod = new DeviceAuthenticationWithRegistrySymmetricKey(deviceID, devicePK);
            deviceClient = InitializeDeviceClient(dpsRegistrationResult.AssignedHub, authMethod);
            Console.WriteLine("Assigned IoT Hub: " + dpsRegistrationResult.AssignedHub);
            return deviceClient;
        }

        private static DeviceClient InitializeDeviceClient(string hostname, IAuthenticationMethod authenticationMethod)
        {
            DeviceClient deviceClient = DeviceClient.Create(hostname, authenticationMethod, TransportType.Mqtt);
            return deviceClient;
        }
    }
}
