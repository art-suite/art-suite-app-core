"use strict"
let Caf = require('caffeine-script-runtime');
Caf.defMod(module, () => {return Caf.importInvoke(["BaseObject", "hardDeprecatedFunctionsAsMap", "merge", "min", "Math", "validateInputs", "Object", "pending", "toSeconds", "max", "timeoutAt", "failure", "isSuccess", "isFailure", "networkFailure", "serverFailure", "formattedInspect", "log", "propsEq", "pushIfNotPresent", "removeFirstMatch", "models"], [global, require('./StandardImport'), require('./ModelRegistry'), require('./Lib')], (BaseObject, hardDeprecatedFunctionsAsMap, merge, min, Math, validateInputs, Object, pending, toSeconds, max, timeoutAt, failure, isSuccess, isFailure, networkFailure, serverFailure, formattedInspect, log, propsEq, pushIfNotPresent, removeFirstMatch, models) => {let getStore, retryExponent, FluxEntry; getStore = function() {let _store; return _store != null ? _store : _store = require('./Store').store;}; retryExponent = 2; return FluxEntry = Caf.defClass(class FluxEntry extends BaseObject {constructor(modelName, key, initialFluxRecord = {}) {let temp, temp1; super(...arguments); this._model = models[modelName]; this._autoReload = this._model.autoReloadEnabled; this._currentPendingReload = null; ((temp = initialFluxRecord.key) != null ? temp : initialFluxRecord.key = key); ((temp1 = initialFluxRecord.modelName) != null ? temp1 : initialFluxRecord.modelName = modelName); this.setFluxRecord(initialFluxRecord); this._subscribers = []; this._previousFluxRecord = null;};}, function(FluxEntry, classSuper, instanceSuper) {this.getter("previousFluxRecord", "fluxRecord", "subscribers", "model", "autoReload"); this.getter({subscriberCount: function() {return this._subscribers.length;}, key: function() {return this._fluxRecord.key;}, modelName: function() {return this._fluxRecord.modelName;}, status: function() {return this._fluxRecord.status;}, inspectedObjects: function() {return merge({modelName: this.modelName, key: this.key, status: this.status, createdAt: this.createdAt, updatedAt: this.updatedAt, reloadAt: this.reloadAt, data: this.fluxRecord.data, message: this.fluxRecord.message, error: this.fluxRecord.error});}, nextNetworkFailureRetryDelay: function() {let m, temp; return (0 < (m = this.model.getMinNetworkFailureReloadSeconds())) ? min(m * Math.pow(((temp = this.tryCount) != null ? temp : 1), retryExponent), this.model.getMaxNetworkFailureReloadSeconds()) : undefined;}, nextServerFailureRetryDelay: function() {let m, temp; return (0 < (m = this.model.getMinServerFailureReloadSeconds())) ? min(m * Math.pow(((temp = this.tryCount) != null ? temp : 1), retryExponent), this.model.getMaxServerFailureReloadSeconds()) : undefined;}}); this.getter(hardDeprecatedFunctionsAsMap("dataChanged", "fluxRecordChanged", "age", "plainStructure", "hasSubscribers")); Caf.each2(["tryCount", "reloadAt", "updatedAt", "createdAt"], (fluxRecordSetter) => {this.getter({[fluxRecordSetter]: function() {return this._fluxRecord[fluxRecordSetter];}}); return this.setter({[fluxRecordSetter]: function(v) {return this._fluxRecord[fluxRecordSetter] = v;}});}); this.setter({fluxRecord: function(newFluxRecord) {let key, modelName, createdAt, now, temp, temp1, temp2; validateInputs(Caf.is(newFluxRecord, Object), "New fluxRecord must be an object.", newFluxRecord); temp = ((temp1 = this._fluxRecord) != null ? temp1 : newFluxRecord); key = temp.key; modelName = temp.modelName; createdAt = temp.createdAt; this._fluxRecord = newFluxRecord; newFluxRecord.key = key; newFluxRecord.modelName = modelName; ((temp2 = newFluxRecord.status) != null ? temp2 : newFluxRecord.status = pending); newFluxRecord.updatedAt = now = toSeconds(); newFluxRecord.createdAt = createdAt != null ? createdAt : now; return this._autoReload ? this._updateAutoReloadFields() : undefined;}}); this.prototype.scheduleReload = function(reloadDelta) {let reloadAt, delta, now, rangePerterbation, rangeMin, rangeMax, modelName, key, thisPendingReload, temp; return (reloadDelta > 0) ? (reloadAt = this.updatedAt + reloadDelta, delta = max(1, reloadAt - (now = toSeconds())), rangePerterbation = (delta < 80) ? 1 : 15, rangeMin = delta - rangePerterbation, rangeMax = delta + rangePerterbation, !(this.reloadAt < now + rangeMax) ? (this.reloadAt = now + rangeMin + (rangeMax - rangeMin) * Math.random(), (temp = this, modelName = temp.modelName, key = temp.key), this._currentPendingReload = thisPendingReload = timeoutAt(this.reloadAt, function() {let entry; entry = getStore()._getEntry(modelName, key); return (thisPendingReload === (Caf.exists(entry) && entry._currentPendingReload)) ? (entry._resetAutoReload(), entry.reload()) : undefined;})) : undefined) : undefined;}; this.prototype.reload = function() {return this.model.reload(this.key);}; this.prototype.load = function() {let fluxRecord, error; try {if (fluxRecord = this.model.load(this.key)) {this.setFluxRecord(fluxRecord);};} catch (error1) {error = error1; this.setFluxRecord({error, status: failure, message: this._getAndLogErrorMessage(error, "loading")});}; return this;}; this.prototype.added = function() {return this.model.storeEntryAdded(this);}; this.prototype.removed = function() {return this.model.storeEntryRemoved(this);}; this.prototype.updated = function() {this.model.storeEntryUpdated(this); return this._notifySubscribers();}; this.prototype._resetAutoReload = function() {this._currentPendingReload = this.reloadAt = null; return this.tryCount = 0;}; this.prototype._updateAutoReloadFields = function() {return isSuccess(this.status) ? (this.tryCount = 1, this.scheduleReload(this.model.getStaleDataReloadSeconds())) : isFailure(this.status) ? (this.tryCount += 1, (() => {switch (this.status) {case networkFailure: return this.scheduleReload(this.nextNetworkFailureRetryDelay); case serverFailure: case failure: return this.scheduleReload(this.nextServerFailureRetryDelay);};})()) : undefined;}; this.prototype._getAndLogErrorMessage = function(error, failedAction, _log = log.error) {let message; _log({error, message: message = `Error ${Caf.toString(failedAction)} Entry for model: ${Caf.toString(this.modelName)}, key: ${Caf.toString(formattedInspect(this.key))}`}); return message;}; this.prototype._updateFluxRecord = function(updateFunction) {let error, temp; ((temp = this._previousFluxRecord) != null ? temp : this._previousFluxRecord = this._fluxRecord); try {this.setFluxRecord(Caf.isF(updateFunction) && updateFunction(this._fluxRecord) || {});} catch (error1) {error = error1; this._getAndLogErrorMessage(error, "updating");}; return propsEq(this._fluxRecord, this._previousFluxRecord) ? this._previousFluxRecord = null : undefined;}; this.prototype._notifySubscribers = function() {let from, into, to, i, temp; return this._previousFluxRecord ? ((from = this._subscribers, into = from, (from != null) ? (to = from.length, i = 0, (() => {while (i < to) {let subscriber; subscriber = from[i]; subscriber(this._fluxRecord, this._previousFluxRecord); temp = i++;}; return temp;})()) : undefined, into), this._previousFluxRecord = null) : undefined;}; this.prototype._subscribe = function(subscriber) {return pushIfNotPresent(this._subscribers, subscriber);}; this.prototype._unsubscribe = function(subscriber) {return removeFirstMatch(this._subscribers, subscriber);};});});});
//# sourceMappingURL=FluxEntry.js.map
