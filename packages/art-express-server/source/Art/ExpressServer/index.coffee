# generated by Neptune Namespaces v2.x.x
# file: Art/ExpressServer/index.coffee

module.exports = require './namespace'
module.exports
.includeInNamespace require './ExpressServer'
.addModules
  AllowAllCorsHandler: require './AllowAllCorsHandler'
  LoggingMixin:        require './LoggingMixin'       
  PromiseHandler:      require './PromiseHandler'     
  Server:              require './Server'             