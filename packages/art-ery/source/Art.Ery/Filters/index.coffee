# generated by Neptune Namespaces v3.x.x
# file: Art.Ery/Filters/index.coffee

module.exports = require './namespace'
module.exports
.includeInNamespace require './Filters'
.addModules
  AfterEventsFilter:                   require './AfterEventsFilter'                  
  DataUpdatesFilter:                   require './DataUpdatesFilter'                  
  LinkFieldsFilter:                    require './LinkFieldsFilter'                   
  LinkFieldsFilter2:                   require './LinkFieldsFilter2'                  
  LinkFieldsFilter2LegacyApiDecode:    require './LinkFieldsFilter2LegacyApiDecode'   
  LinkFieldsFilter2LegacyApiEncode:    require './LinkFieldsFilter2LegacyApiEncode'   
  LinkFieldsFilter2Transition2BFilter: require './LinkFieldsFilter2Transition2BFilter'
  PrefetchedRecordsFilter:             require './PrefetchedRecordsFilter'            
  TimestampFilter:                     require './TimestampFilter'                    
  UniqueIdFilter:                      require './UniqueIdFilter'                     
  UserOwnedFilter:                     require './UserOwnedFilter'                    
  UuidFilter:                          require './UuidFilter'                         
  ValidationFilter:                    require './ValidationFilter'                   