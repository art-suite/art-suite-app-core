# generated by Neptune Namespaces v2.x.x
# file: Art/Aws/namespace.coffee

Art = require '../namespace'
module.exports = Art.Aws ||
Art.addNamespace 'Aws', class Aws extends Neptune.Base
  ;
require './StreamlinedDynamoDbApi/namespace'