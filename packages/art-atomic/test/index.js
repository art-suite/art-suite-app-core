mocha = require("mocha")
// mocha.setup('tdd');

global.suite = describe
global.suiteSetup = beforeEach
global.setup = before
global.teardown = after
global.suiteTeardown = afterEach
global.test = it
require('coffee-script/register');
require('./tests/art/atomic/color');
