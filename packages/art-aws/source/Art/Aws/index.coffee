# generated by Neptune Namespaces v3.x.x
# file: Art/Aws/index.coffee

module.exports = require './namespace'
module.exports
.includeInNamespace require './Aws'
.addModules
  Aws4RestClient: require './Aws4RestClient'
  Config:         require './Config'        
  DynamoDb:       require './DynamoDb'      
  Elasticsearch:  require './Elasticsearch' 
  S3:             require './S3'            
require './StreamlinedDynamoDbApi'