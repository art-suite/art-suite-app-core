"use strict"
let Caf = require('caffeine-script-runtime');
Caf.defMod(module, () => {return Caf.importInvoke(["describe", "beforeEach", "_resetArtSuiteModels", "test", "Promise", "ArtModel", "artModelStore", "assert", "pending", "missing", "timeout", "success", "log", "afterEach", "models"], [global, require('./StandardImport')], (describe, beforeEach, _resetArtSuiteModels, test, Promise, ArtModel, artModelStore, assert, pending, missing, timeout, success, log, afterEach, models) => {return describe({load: function() {beforeEach(_resetArtSuiteModels); test("model with async load", () => new Promise((resolve) => {let MyBasicModel, res; MyBasicModel = Caf.defClass(class MyBasicModel extends ArtModel {}, function(MyBasicModel, classSuper, instanceSuper) {this.prototype.load = function(key) {artModelStore.onNextReady(() => this.updateModelRecord(key, {status: missing})); return null;};}); res = artModelStore.subscribe("myBasicModel", "123", (modelRecord) => {if (!(modelRecord.status !== pending)) {return;}; assert.selectedEq({status: missing, key: "123", modelName: "myBasicModel"}, modelRecord); return resolve();}); return assert.selectedEq({status: pending, key: "123", modelName: "myBasicModel"}, res);})); test("model with @loadModelRecord", () => new Promise((resolve) => {let MyBasicModel, res; MyBasicModel = Caf.defClass(class MyBasicModel extends ArtModel {}, function(MyBasicModel, classSuper, instanceSuper) {this.prototype.loadModelRecord = function(key) {return timeout(20).then(() => {return {status: missing};});};}); res = artModelStore.subscribe("myBasicModel", "123", (modelRecord) => {if (!(modelRecord.status !== pending)) {return;}; assert.selectedEq({status: missing, key: "123", modelName: "myBasicModel"}, modelRecord); return resolve();}); return assert.selectedEq({status: pending, key: "123", modelName: "myBasicModel"}, res);})); test("model with custom load - delayed", () => {let MyBasicModel; MyBasicModel = Caf.defClass(class MyBasicModel extends ArtModel {}, function(MyBasicModel, classSuper, instanceSuper) {this.prototype.load = function(key, callback) {this.updateModelRecord(key, () => {return {status: success, data: {theKeyIs: key}};}); return null;};}); return (new Promise((resolve) => {let res; res = artModelStore.subscribe("myBasicModel", "123", (modelRecord) => {assert.selectedEq({status: success, key: "123", modelName: "myBasicModel", data: {theKeyIs: "123"}}, modelRecord); return resolve();}); return assert.selectedEq({status: pending, key: "123", modelName: "myBasicModel"}, res);})).then(() => new Promise((resolve) => artModelStore.subscribe("myBasicModel", "456", (modelRecord) => {assert.selectedEq({status: success, key: "456", modelName: "myBasicModel", data: {theKeyIs: "456"}}, modelRecord); return resolve();})));}); test("model with custom load - immediate", () => {let MyBasicModel; MyBasicModel = Caf.defClass(class MyBasicModel extends ArtModel {}, function(MyBasicModel, classSuper, instanceSuper) {this.prototype.load = function(key, callback) {return this.updateModelRecord(key, {status: success, data: {theKeyIs: key}});};}); return new Promise((resolve, reject) => {let res; res = artModelStore.subscribe("myBasicModel", "123", (modelRecord) => {log.error("THIS SHOULDN'T HAPPEN!"); return reject();}); assert.selectedEq({status: success, key: "123", modelName: "myBasicModel", data: {theKeyIs: "123"}}, res); return artModelStore.onNextReady(resolve);});}); return test("model with @loadData", () => {let MyBasicModel; MyBasicModel = Caf.defClass(class MyBasicModel extends ArtModel {}, function(MyBasicModel, classSuper, instanceSuper) {this.prototype.loadData = function(key) {return Promise.resolve({theKeyIs: key});};}); return (new Promise((resolve) => artModelStore.subscribe("myBasicModel", "123", (modelRecord) => {assert.selectedEq({status: success, key: "123", modelName: "myBasicModel", data: {theKeyIs: "123"}}, modelRecord); return resolve();}))).then(() => new Promise((resolve) => artModelStore.subscribe("myBasicModel", "456", (modelRecord) => {assert.selectedEq({status: success, key: "456", modelName: "myBasicModel", data: {theKeyIs: "456"}}, modelRecord); return resolve();})));});}, simultanious: function() {beforeEach(_resetArtSuiteModels); test("two simultantious ArtModel requests on the same key only triggers one artModelStore request", () => {let counts, MyBasicModel; counts = {load: 0, subscription1: 0, subscription2: 0}; MyBasicModel = Caf.defClass(class MyBasicModel extends ArtModel {}, function(MyBasicModel, classSuper, instanceSuper) {this.prototype.load = function(key, callback) {counts.load++; return this.updateModelRecord(key, {status: success, data: {theKeyIs: key}});};}); artModelStore.subscribe("myBasicModel", "123", (modelRecord) => {assert.eq(modelRecord.count, 2); return counts.subscription1++;}); artModelStore.subscribe("myBasicModel", "123", (modelRecord) => {assert.eq(modelRecord.count, 2); return counts.subscription2++;}); artModelStore.update("myBasicModel", "123", (modelRecord) => {return {count: (modelRecord.count || 0) + 1};}); artModelStore.update("myBasicModel", "123", (modelRecord) => {return {count: (modelRecord.count || 0) + 1};}); return artModelStore.onNextReady(() => assert.eq(counts, {load: 1, subscription1: 1, subscription2: 1}));}); return test("two simultantious ArtModel requests on the different keys triggers two artModelStore requests", () => {let counts, MyBasicModel; counts = {load: 0, sub1: 0, sub2: 0}; MyBasicModel = Caf.defClass(class MyBasicModel extends ArtModel {}, function(MyBasicModel, classSuper, instanceSuper) {this.prototype.load = function(key, callback) {counts.load++; return this.updateModelRecord(key, {status: success, data: {theKeyIs: key}});};}); artModelStore.subscribe("myBasicModel", "123", (modelRecord) => {assert.eq(modelRecord.count, 1); return counts.sub1++;}); artModelStore.subscribe("myBasicModel", "456", (modelRecord) => {assert.eq(modelRecord.count, 1); return counts.sub2++;}); artModelStore.update("myBasicModel", "123", (modelRecord) => {return {count: (modelRecord.count || 0) + 1};}); artModelStore.update("myBasicModel", "456", (modelRecord) => {return {count: (modelRecord.count || 0) + 1};}); return artModelStore.onNextReady(() => assert.eq(counts, {load: 2, sub1: 1, sub2: 1}));});}, loadPromise: function() {beforeEach(_resetArtSuiteModels); afterEach(() => artModelStore.onNextReady()); return test("multiple loadPromises with the same key only load once", () => {let loadCount, User, p1, p2, p3; loadCount = 0; User = Caf.defClass(class User extends ArtModel {}, function(User, classSuper, instanceSuper) {this.prototype.loadData = function(key) {return timeout(10).then(() => {loadCount++; return {id: key, userName: "fred"};});};}); p1 = models.user.loadPromise("abc"); p2 = models.user.loadPromise("abc"); p3 = models.user.loadPromise("def"); return Promise.all([p1, p2, p3]).then(() => {assert.eq(loadCount, 2); assert.eq(p1, p2); return assert.neq(p1, p3);});});}, aliases: function() {beforeEach(_resetArtSuiteModels); return test("@aliases adds aliases to the model registry", () => {let User; User = Caf.defClass(class User extends ArtModel {}, function(User, classSuper, instanceSuper) {this.aliases("owner", "sister");}); assert.eq(models.user.class, User); assert.eq(models.user, models.owner); return assert.eq(models.user, models.sister);});}, functionsBoundToInstances: function() {beforeEach(_resetArtSuiteModels); return test("use bound function", () => {let User, user, foo; User = Caf.defClass(class User extends ArtModel {}, function(User, classSuper, instanceSuper) {this.prototype.foo = function() {return this._foo = (this._foo || 0) + 1;};}); ({user} = User); ({foo} = user); foo(); assert.eq(user._foo, 1); foo(); return assert.eq(user._foo, 2);});}});});});
//# sourceMappingURL=ArtModel.test.js.map
