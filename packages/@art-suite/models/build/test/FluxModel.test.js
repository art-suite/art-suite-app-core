"use strict"
let Caf = require('caffeine-script-runtime');
Caf.defMod(module, () => {return Caf.importInvoke(["describe", "test", "Promise", "_reset", "Model", "store", "assert", "pending", "missing", "timeout", "success", "log", "afterEach", "models"], [global, require('./StandardImport')], (describe, test, Promise, _reset, Model, store, assert, pending, missing, timeout, success, log, afterEach, models) => {return describe({load: function() {test("model with async load", () => new Promise((resolve) => {let MyBasicModel, res; _reset(); MyBasicModel = Caf.defClass(class MyBasicModel extends Model {}, function(MyBasicModel, classSuper, instanceSuper) {this.prototype.load = function(key) {store.onNextReady(() => this.updateStore(key, {status: missing})); return null;};}); res = store.subscribe("myBasicModel", "123", (fluxRecord) => {if (!(fluxRecord.status !== pending)) {return;}; assert.selectedEq({status: missing, key: "123", modelName: "myBasicModel"}, fluxRecord); return resolve();}); return assert.selectedEq({status: pending, key: "123", modelName: "myBasicModel"}, res);})); test("model with @loadFluxRecord", () => new Promise((resolve) => {let MyBasicModel, res; _reset(); MyBasicModel = Caf.defClass(class MyBasicModel extends Model {}, function(MyBasicModel, classSuper, instanceSuper) {this.prototype.loadFluxRecord = function(key) {return timeout(20).then(() => {return {status: missing};});};}); res = store.subscribe("myBasicModel", "123", (fluxRecord) => {if (!(fluxRecord.status !== pending)) {return;}; assert.selectedEq({status: missing, key: "123", modelName: "myBasicModel"}, fluxRecord); return resolve();}); return assert.selectedEq({status: pending, key: "123", modelName: "myBasicModel"}, res);})); test("model with custom load - delayed", () => {let MyBasicModel; _reset(); MyBasicModel = Caf.defClass(class MyBasicModel extends Model {}, function(MyBasicModel, classSuper, instanceSuper) {this.prototype.load = function(key, callback) {this.updateStore(key, () => {return {status: success, data: {theKeyIs: key}};}); return null;};}); return (new Promise((resolve) => {let res; res = store.subscribe("myBasicModel", "123", (fluxRecord) => {assert.selectedEq({status: success, key: "123", modelName: "myBasicModel", data: {theKeyIs: "123"}}, fluxRecord); return resolve();}); return assert.selectedEq({status: pending, key: "123", modelName: "myBasicModel"}, res);})).then(() => new Promise((resolve) => store.subscribe("myBasicModel", "456", (fluxRecord) => {assert.selectedEq({status: success, key: "456", modelName: "myBasicModel", data: {theKeyIs: "456"}}, fluxRecord); return resolve();})));}); test("model with custom load - immediate", () => {let MyBasicModel; _reset(); MyBasicModel = Caf.defClass(class MyBasicModel extends Model {}, function(MyBasicModel, classSuper, instanceSuper) {this.prototype.load = function(key, callback) {return this.updateStore(key, {status: success, data: {theKeyIs: key}});};}); return new Promise((resolve, reject) => {let res; res = store.subscribe("myBasicModel", "123", (fluxRecord) => {log.error("THIS SHOULDN'T HAPPEN!"); return reject();}); assert.selectedEq({status: success, key: "123", modelName: "myBasicModel", data: {theKeyIs: "123"}}, res); return store.onNextReady(resolve);});}); return test("model with @loadData", () => {let MyBasicModel; _reset(); MyBasicModel = Caf.defClass(class MyBasicModel extends Model {}, function(MyBasicModel, classSuper, instanceSuper) {this.prototype.loadData = function(key) {return Promise.resolve({theKeyIs: key});};}); return (new Promise((resolve) => store.subscribe("myBasicModel", "123", (fluxRecord) => {assert.selectedEq({status: success, key: "123", modelName: "myBasicModel", data: {theKeyIs: "123"}}, fluxRecord); return resolve();}))).then(() => new Promise((resolve) => store.subscribe("myBasicModel", "456", (fluxRecord) => {assert.selectedEq({status: success, key: "456", modelName: "myBasicModel", data: {theKeyIs: "456"}}, fluxRecord); return resolve();})));});}, simultanious: function() {test("two simultantious Model requests on the same key only triggers one store request", () => {let counts, MyBasicModel; _reset(); counts = {load: 0, subscription1: 0, subscription2: 0}; MyBasicModel = Caf.defClass(class MyBasicModel extends Model {}, function(MyBasicModel, classSuper, instanceSuper) {this.prototype.load = function(key, callback) {counts.load++; return this.updateStore(key, {status: success, data: {theKeyIs: key}});};}); store.subscribe("myBasicModel", "123", (fluxRecord) => {assert.eq(fluxRecord.count, 2); return counts.subscription1++;}); store.subscribe("myBasicModel", "123", (fluxRecord) => {assert.eq(fluxRecord.count, 2); return counts.subscription2++;}); store.update("myBasicModel", "123", (fluxRecord) => {return {count: (fluxRecord.count || 0) + 1};}); store.update("myBasicModel", "123", (fluxRecord) => {return {count: (fluxRecord.count || 0) + 1};}); return store.onNextReady(() => assert.eq(counts, {load: 1, subscription1: 1, subscription2: 1}));}); return test("two simultantious Model requests on the different keys triggers two store requests", () => {let counts, MyBasicModel; _reset(); counts = {load: 0, sub1: 0, sub2: 0}; MyBasicModel = Caf.defClass(class MyBasicModel extends Model {}, function(MyBasicModel, classSuper, instanceSuper) {this.prototype.load = function(key, callback) {counts.load++; return this.updateStore(key, {status: success, data: {theKeyIs: key}});};}); store.subscribe("myBasicModel", "123", (fluxRecord) => {assert.eq(fluxRecord.count, 1); return counts.sub1++;}); store.subscribe("myBasicModel", "456", (fluxRecord) => {assert.eq(fluxRecord.count, 1); return counts.sub2++;}); store.update("myBasicModel", "123", (fluxRecord) => {return {count: (fluxRecord.count || 0) + 1};}); store.update("myBasicModel", "456", (fluxRecord) => {return {count: (fluxRecord.count || 0) + 1};}); return store.onNextReady(() => assert.eq(counts, {load: 2, sub1: 1, sub2: 1}));});}, loadPromise: function() {afterEach(() => store.onNextReady()); return test("multiple loadPromises with the same key only load once", () => {let loadCount, User, p1, p2, p3; _reset(); loadCount = 0; User = Caf.defClass(class User extends Model {}, function(User, classSuper, instanceSuper) {this.prototype.loadData = function(key) {return timeout(10).then(() => {loadCount++; return {id: key, userName: "fred"};});};}); p1 = models.user.loadPromise("abc"); p2 = models.user.loadPromise("abc"); p3 = models.user.loadPromise("def"); return Promise.all([p1, p2, p3]).then(() => {assert.eq(loadCount, 2); assert.eq(p1, p2); return assert.neq(p1, p3);});});}, aliases: function() {return test("@aliases adds aliases to the model registry", () => {let User; _reset(); User = Caf.defClass(class User extends Model {}, function(User, classSuper, instanceSuper) {this.aliases("owner", "sister");}); assert.eq(models.user.class, User); assert.eq(models.user, models.owner); return assert.eq(models.user, models.sister);});}, functionsBoundToInstances: function() {return test("use bound function", () => {let User, user, foo; _reset(); User = Caf.defClass(class User extends Model {}, function(User, classSuper, instanceSuper) {this.prototype.foo = function() {return this._foo = (this._foo || 0) + 1;};}); ({user} = User); ({foo} = user); foo(); assert.eq(user._foo, 1); foo(); return assert.eq(user._foo, 2);});}});});});
//# sourceMappingURL=FluxModel.test.js.map
