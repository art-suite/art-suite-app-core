# generated by Neptune Namespaces v3.x.x
# file: Art/Engine/Elements/index.coffee

module.exports = require './namespace'
module.exports
.includeInNamespace require './Elements'
.addModules
  AtomElement:       require './AtomElement'      
  ShadowableElement: require './ShadowableElement'
require './Filters'
require './ShapeChildren'
require './Shapes'
require './Widgets'