# generated by Neptune Namespaces v2.x.x
# file: Art/Suite/Demos/namespace.coffee

Suite = require '../namespace'
module.exports = Suite.Demos ||
Suite.addNamespace 'Demos', class Demos extends Neptune.Base
  ;
require './Animations/namespace';
require './Basic/namespace';
require './BasicHotLoading/namespace';
require './CandyStripe/namespace';
require './Chat/namespace';
require './Clock/namespace';
require './ColorExtractor/namespace';
require './ColorPicker/namespace';
require './Physics/namespace';
require './Quixx/namespace';
require './ScrollingDynamic/namespace';
require './ScrollingInfinite/namespace';
require './Todos/namespace';
require './VoidProps/namespace'