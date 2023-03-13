// ****************************************
// Azure Bicep main template
// This bicep template demonstrates publishing an existing API end-point to an existing API maangement instance.
// The example illustrates using the "existing" term for an exisitng resource and then also importing an API end-point with OpenDocs specificatons to API management
// ****************************************
//refer to existing APIM
targetScope = 'resourceGroup'

//required parameters
param apimInstanceName string // need to be provided since it is existing
param apimRG string //resource group of existing APIM instance
param apiName string

//needed and default value
param apiEndPointURL string = 'http://petstore.swagger.io/v2/swagger.json'
param apiPath string = 'AzureFunctionsApi'

@allowed([
  'openapi'
  'openapi+json'
  'openapi+json-link'
  'swagger-json'
  'swagger-link-json'
  'wadl-link-json'
  'wadl-xml'
  'wsdl'
  'wsdl-link'
])
@description('Type of OpenAPI we are importing')
param apiFormat string = 'swagger-link-json'

//we maintain here a record of products to use. These products may / may not exists.
var productsSet = [
  {
    productName: 'Starter'
    displayName: 'Starter'
    productDescription: 'Starter product'
    productTerms: 'Tems and conditions here for this product'
    isSubscriptionRequired: true
    isApprovalRequired: false
    subscriptionLimit: 3
    publishState: 'published' // may be 'notPublished'
  }
  {
    productName: 'Unlimited'
    displayName: 'Unlimited'
    productDescription: 'Unlimited Product'
    productTerms: 'Tems and conditions here for this product'
    isSubscriptionRequired: true
    isApprovalRequired: true
    subscriptionLimit: 3
    publishState: 'published' // may be 'notPublished'
  }
]

//we refer to exisitng APIM instance. This may even be in a different resoruce group
resource apiManagementService 'Microsoft.ApiManagement/service@2020-12-01' existing = {
  name: apimInstanceName
}

//establish one or many products to an existing APIM instance
resource ProductRecords 'Microsoft.ApiManagement/service/products@2020-12-01' = [for product in productsSet: {
  parent: apiManagementService
  name: product.productName
  properties: {
    displayName: product.displayName
    description: product.productDescription
    terms: product.productTerms
    subscriptionRequired: product.isSubscriptionRequired
    approvalRequired: product.isApprovalRequired
    subscriptionsLimit: product.subscriptionLimit
    state: product.publishState
  }
}]

resource petStoreApiExample 'Microsoft.ApiManagement/service/apis@2020-06-01-preview' = {
  parent: apiManagementService
  name: 'PetStore'
  properties: {
    format: 'swagger-link-json'
    value: 'http://petstore.swagger.io/v2/swagger.json'
    path: 'petstore'
  }
}

//attach API to product(s)
resource attachAPIToProducts 'Microsoft.ApiManagement/service/products/apis@2020-12-01' = [for (product, i) in productsSet: {
  parent: ProductRecords[i]
  //name: apiName
  name: petStoreApiExample.name
}]

output apimProducts array = [for (name, i) in productsSet: {
  productId: ProductRecords[i].id
  productName: ProductRecords[i].name
}]



