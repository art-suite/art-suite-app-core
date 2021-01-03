"use strict"
let Caf = require('caffeine-script-runtime');
Caf.defMod(module, () => {return Caf.importInvoke(["describe", "beforeEach", "_reset", "afterEach", "test", "store", "Promise", "Model", "FluxSubscriptionsMixin", "chainedTest", "BaseObject", "assert", "pending", "missing"], [global, require('./StandardImport'), {ApplicationState: require('./ApplicationState')}], (describe, beforeEach, _reset, afterEach, test, store, Promise, Model, FluxSubscriptionsMixin, chainedTest, BaseObject, assert, pending, missing) => {return describe({subscribeOnModelRegistered: function() {beforeEach(_reset); afterEach(() => store.onNextReady()); return test("subscribeOnModelRegistered", () => new Promise((resolve, reject) => {let MyModelB, MyModelA; MyModelB = Caf.defClass(class MyModelB extends Model {}); return MyModelA = Caf.defClass(class MyModelA extends FluxSubscriptionsMixin(Model) {constructor() {super(...arguments); this.subscribeOnModelRegistered("mySubscriptionKey", "myModelB", "myFluxKey", {updatesCallback: () => {}}).then(resolve, reject);};});}));}, "subscribe and initialFluxRecord": function() {chainedTest("with stateField and initialFluxRecord", () => {let MyModel, MyObject; _reset(); MyModel = Caf.defClass(class MyModel extends require('./ApplicationState') {}); new (MyObject = Caf.defClass(class MyObject extends FluxSubscriptionsMixin(BaseObject) {constructor() {super(...arguments); this.subscribe("mySubscriptionKey", "myModel", "myFluxKey", {initialFluxRecord: {data: "myInitialData"}, stateField: "myStateField"});};})); assert.selectedEq({status: pending, data: "myInitialData", key: "myFluxKey", modelName: "myModel"}, store.get("myModel", "myFluxKey")); return store.onNextReady();}); return test("with stateField and no initialFluxRecord", () => {let MyModel, MyObject; _reset(); MyModel = Caf.defClass(class MyModel extends require('./ApplicationState') {}); new (MyObject = Caf.defClass(class MyObject extends FluxSubscriptionsMixin(BaseObject) {constructor() {super(...arguments); this.subscribe("mySubscriptionKey", "myModel", "myFluxKey", {stateField: "myStateField"});};})); return assert.selectedEq({status: missing, key: "myFluxKey", modelName: "myModel"}, store.get("myModel", "myFluxKey"));});}});});});
//# sourceMappingURL=FluxSubscriptionMixin.test.js.map
