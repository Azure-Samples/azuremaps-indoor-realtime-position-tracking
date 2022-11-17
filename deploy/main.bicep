// Azure Maps real time position tracking demo project
@description('Azure Maps real time position tracking demo project.')
@minLength(1)
@maxLength(11)
param projectName string = 'azuremaps'

@description('The location to use for all deployments.')
param location string = resourceGroup().location

@description('The SKU to use for the IoT Hub.')
var skuName = 'B1'

@description('The number of IoT Hub units.')
var skuUnits = 1

@description('Partitions used for the event stream.')
var d2cPartitions = 4

var iotHubName = '${projectName}Hub${uniqueString(resourceGroup().id)}'
var storageAccountName = '${toLower(projectName)}${uniqueString(resourceGroup().id)}'
var storageEndpoint1 = 'iotclogs'
var routeName1 = '${storageEndpoint1}-route'
var storageContainerName1 = 'iotclogs'
var storageContainerName2 = 'public'

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    cors: {
      corsRules: [
        {
          allowedHeaders: [
            ''
          ]
          allowedMethods: [
            'GET'
          ]
          allowedOrigins: [
            '*'
          ]
          exposedHeaders: [
            ''
          ]
          maxAgeInSeconds: 0
        }
      ]
    }
  }
}

resource container1 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: '${storageAccountName}/default/${storageContainerName1}'
  properties: {
    publicAccess: 'None'
  }
  dependsOn: [
    storageAccount
  ]
}

resource container2 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: '${storageAccountName}/default/${storageContainerName2}'
  properties: {
    publicAccess: 'Blob'
  }
  dependsOn: [
    storageAccount
  ]
}

// IoT Hub
resource IoTHub 'Microsoft.Devices/IotHubs@2021-07-02' = {
  name: iotHubName
  location: location
  sku: {
    name: skuName
    capacity: skuUnits
  }
  properties: {
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: d2cPartitions
      }
    }
    routing: {
      endpoints: {
        storageContainers: [
          {
            connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
            containerName: storageContainerName1
            fileNameFormat: '{iothub}/{partition}/{YYYY}/{MM}/{DD}/{HH}/{mm}'
            batchFrequencyInSeconds: 100
            maxChunkSizeInBytes: 104857600
            encoding: 'JSON'
            name: storageEndpoint1
          }
        ]
      }
      routes: [
        {
          name: routeName1
          source: 'DeviceMessages'
          condition: 'true'
          endpointNames: [
            storageEndpoint1
          ]
          isEnabled: true
        }
        {
          name: 'fallback-route'
          source: 'DeviceMessages'
          condition: 'true'
          endpointNames: [
            'events'
          ]
          isEnabled: true
        }
      ]
    }
    messagingEndpoints: {
      fileNotifications: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
    enableFileUploadNotifications: false
    cloudToDevice: {
      maxDeliveryCount: 10
      defaultTtlAsIso8601: 'PT1H'
      feedback: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
  }
}

// Web PubSub
@description('The name for your new Web PubSub instance.')
var wpsName = '${toLower(projectName)}${uniqueString(resourceGroup().id)}'

@description('Unit count')
var UnitCount = 1

@description('SKU name')
var Sku = 'Free_F1'

@description('Pricing tier')
var PricingTier = 'Free'

// Resource definition
resource webpubsub 'Microsoft.SignalRService/webPubSub@2021-10-01' = {
  name: wpsName
  location: location
  sku: {
    capacity: UnitCount
    name: Sku
    tier: PricingTier
  }
  identity: {
    type: 'None'
  }
  properties: {
    disableAadAuth: false
    disableLocalAuth: false
    liveTraceConfiguration: {
      categories: [
        {
          enabled: 'false'
          name: 'ConnectivityLogs'
        }
        {
          enabled: 'false'
          name: 'MessagingLogs'
        }
      ]
      enabled: 'false'
    }
    networkACLs: {
      defaultAction: 'Deny'     
      publicNetwork: {
        allow: [
          'ServerConnection'
          'ClientConnection'
          'RESTAPI'
          'Trace'
        ]
      }
    }
    publicNetworkAccess: 'Enabled'
    resourceLogConfiguration: {
      categories: [
        {
          enabled: 'true'
          name: 'ConnectivityLogs'
        }
        {
          enabled: 'true'
          name: 'MessagingLogs'
        }
      ]
    }
    tls: {
      clientCertEnabled: false
    }
  }
}

// Azure Maps instance
resource azureMaps 'Microsoft.Maps/accounts@2021-12-01-preview' = {
  name: '${toLower(projectName)}${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'G2'
  }
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: [
            '*'
          ]
        }
      ]
    }
  }
}

// Function App
@description('The name of the function app that you wish to create.')
var appName = '${toLower(projectName)}${uniqueString(resourceGroup().id)}'

@description('The language worker runtime to load in the function app.')
var runtime = 'node'

var functionAppName = appName
var hostingPlanName = appName
var applicationInsightsName = appName
var functionWorkerRuntime = runtime

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~16'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
        supportCredentials: true
      }
      webSocketsEnabled: true
    }
    httpsOnly: true
  }
}

@description('Current UTC time')
param utcValue string = utcNow()

// Execute post deployment script for configuring resources
resource PostDeploymentscript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'PostDeploymentscript'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
    properties: {
    forceUpdateTag: utcValue
    azCliVersion: '2.15.0'
    arguments: '${IoTHub.name} ${resourceGroup().name} ${location} ${functionApp.id} ${storageAccount.name} ${container2}'
    primaryScriptUri: 'https://raw.githubusercontent.com/Azure-Samples/azuremaps-indoor-realtime-position-tracking/main/deploy/postdeploy.sh'
    supportingScriptUris: []
    timeout: 'PT30M'
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    blobService
    webpubsub
    azureMaps
    hostingPlan
    applicationInsights
  ]
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: '${projectName}scriptidentity'
  location: location
}

output outputInfo object = {
  webAppURL: 'https://${functionApp.name}.azurewebsites.net/api/index?clientId=blobs_extension'
}
