// generated by Neptune Namespaces v4.x.x
// file: tests/Art.Ery/ClientServer/Pipelines/index.js

(module.exports = require('./namespace'))

.addModules({
  Auth:           require('./Auth'),
  ClientFailures: require('./ClientFailures'),
  CompoundKeys:   require('./CompoundKeys'),
  FilterLocation: require('./FilterLocation'),
  MessageRemote:  require('./MessageRemote'),
  MyRemote:       require('./MyRemote'),
  SimpleStore:    require('./SimpleStore'),
  UserRemote:     require('./UserRemote')
});
require('./Transition');