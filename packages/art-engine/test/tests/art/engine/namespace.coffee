# generated by Neptune Namespaces
# file: tests/art/engine/namespace.coffee

Art = require '../namespace'
module.exports = Art.Engine ||
class Art.Engine extends Neptune.Base
  @namespace: Art
  @namespacePath: "Neptune.Tests.Art.Engine"

Art.addNamespace Art.Engine