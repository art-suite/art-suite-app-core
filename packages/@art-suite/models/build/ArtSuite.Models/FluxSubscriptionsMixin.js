// Generated by CoffeeScript 1.12.7
(function() {
  var ModelRegistry, defineModule, fluxStore, isFailure, isFunction, isPlainObject, isString, log, ref, ref1, rubyTrue, success,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  ref = require('art-standard-lib'), isString = ref.isString, defineModule = ref.defineModule, isPlainObject = ref.isPlainObject, rubyTrue = ref.rubyTrue, log = ref.log, isFunction = ref.isFunction;

  ref1 = require('art-communication-status'), success = ref1.success, isFailure = ref1.isFailure;

  fluxStore = require('./FluxStore').fluxStore;

  ModelRegistry = require('./ModelRegistry');

  defineModule(module, function() {
    return function(superClass) {
      var FluxSubscriptionsMixin;
      return FluxSubscriptionsMixin = (function(superClass1) {
        var getRetryNow;

        extend(FluxSubscriptionsMixin, superClass1);

        function FluxSubscriptionsMixin() {
          FluxSubscriptionsMixin.__super__.constructor.apply(this, arguments);
          this._subscriptions = {};
        }

        FluxSubscriptionsMixin.getter({
          models: function() {
            return ModelRegistry.models;
          },
          subscriptions: function() {
            return this._subscriptions;
          }
        });


        /*
        subscribe OR update a subscription
        
        IN:
          subscriptionKey: string (REQUIRED - if no stateField OR modelName)
            Provide a unique key for each active subscription.
            To update the suscription, call @subscribe again with the same subscriptionKey.
            To unsubscribe, call @unsubscribe with the same subscriptionKey.
            DEFAULT: stateField || modelName
        
          modelName: lowerCamelCase string
            if modelName is null/undefined then
              - no subscription will be created.
              - @unsubscribe subscriptionKey will still happen
        
          key: valid input for models[modelName].toKeyString - usually it's a string
            if key is null/undefined then
              - no subscription will be created.
              - @unsubscribe subscriptionKey will still happen
        
          options:
             * if provided, will call @setState(stateField, ...) immediately and with every change
            stateField: string
        
            initialFluxRecord: fluxRecord-style object
        
             * get called with every change
            callback / updatesCallback:  (fluxRecord) -> ignored
        
          NOTE: One of options.stateField OR options.updatesCallback is REQUIRED.
        
        OUT: existingFluxRecord || initialFluxRecord || status: missing fluxRecord
        
        EFFECT:
          Establishes a FluxStore subscription for the given model and fluxKey.
          Upon any changes to the fluxRecord, will:
            call updatesCallback, if provided
            and/or @setStateFromFluxRecord if stateField was provided
        
          Will also call @setStateFromFluxRecord immediately, if stateField is provided,
            with either the initialFluxRecord, or the existing fluxRecord, if any
        
          If there was already a subscription in this object with they same subscriptionKey,
          then @unsubscribe subscriptionKey will be called before setting up the new subscription.
        
          NOTE:
            updateCallback only gets called when fluxRecord changes. It will not be called with the
            current value. HOWEVER, the current fluxRecord is returned from the subscribe call.
        
            If you need to update anything based on the current value, use the return result.
         */

        FluxSubscriptionsMixin.prototype.subscribe = function(subscriptionKey, modelName, key, options) {
          var allOptions, callback, fluxKey, initialFluxRecord, model, stateField, subscriptionFunction, updatesCallback;
          if (isPlainObject(allOptions = subscriptionKey)) {
            subscriptionKey = allOptions.subscriptionKey, modelName = allOptions.modelName, key = allOptions.key, stateField = allOptions.stateField, initialFluxRecord = allOptions.initialFluxRecord, updatesCallback = allOptions.updatesCallback, callback = allOptions.callback;
            if (updatesCallback == null) {
              updatesCallback = callback;
            }
            if (subscriptionKey == null) {
              subscriptionKey = stateField || (modelName + " " + key);
            }
          } else {
            stateField = options.stateField, initialFluxRecord = options.initialFluxRecord, updatesCallback = options.updatesCallback;
          }
          if (!isString(subscriptionKey)) {
            throw new Error("REQUIRED: subscriptionKey");
          }
          if (!(isString(stateField) || isFunction(updatesCallback))) {
            throw new Error("REQUIRED: updatesCallback or stateField");
          }
          this.unsubscribe(subscriptionKey);
          if (!(rubyTrue(key) && modelName)) {
            return this.setStateFromFluxRecord(stateField, initialFluxRecord || {
              status: success
            }, null, key);
          }
          if (!(model = this.models[modelName])) {
            throw new Error("No model registered with the name: " + modelName + ". Registered models:\n  " + (Object.keys(this.models).join("\n  ")));
          }
          fluxKey = model.toKeyString(key);
          subscriptionFunction = (function(_this) {
            return function(fluxRecord) {
              if (typeof updatesCallback === "function") {
                updatesCallback(fluxRecord);
              }
              return _this.setStateFromFluxRecord(stateField, fluxRecord, null, key);
            };
          })(this);
          this._subscriptions[subscriptionKey] = {
            modelName: modelName,
            fluxKey: fluxKey,
            subscriptionFunction: subscriptionFunction
          };
          return this.setStateFromFluxRecord(stateField, fluxStore.subscribe(modelName, fluxKey, subscriptionFunction, initialFluxRecord), initialFluxRecord, key);
        };


        /*
          IN: same as @subscribe
          OUT: promise.then -> # subscription has been created
          USE:
            Primarilly useful for models which want to subscribe to
            other models when they are constructed. This solves the
            loading-order problem.
         */

        FluxSubscriptionsMixin.prototype.subscribeOnModelRegistered = function(subscriptionKeyOrOptions, modelName, fluxKey, options) {
          if (isPlainObject(subscriptionKeyOrOptions)) {
            modelName = subscriptionKeyOrOptions.modelName;
          }
          return ModelRegistry.onModelRegistered(modelName).then((function(_this) {
            return function() {
              return _this.subscribe(subscriptionKeyOrOptions, modelName, fluxKey, options);
            };
          })(this));
        };

        FluxSubscriptionsMixin.prototype.unsubscribe = function(subscriptionKey) {
          var fluxKey, modelName, subscription, subscriptionFunction;
          if (subscription = this._subscriptions[subscriptionKey]) {
            subscriptionFunction = subscription.subscriptionFunction, modelName = subscription.modelName, fluxKey = subscription.fluxKey;
            fluxStore.unsubscribe(modelName, fluxKey, subscriptionFunction);
            delete this._subscriptions[subscriptionKey];
          }
          return null;
        };

        FluxSubscriptionsMixin.prototype.unsubscribeAll = function() {
          var __, ref2, subscriptionKey;
          ref2 = this._subscriptions;
          for (subscriptionKey in ref2) {
            __ = ref2[subscriptionKey];
            this.unsubscribe(subscriptionKey);
          }
          return null;
        };

        getRetryNow = function(modelName, key) {
          return function() {
            return fluxStore._getEntry(modelName, key).reload();
          };
        };

        FluxSubscriptionsMixin.prototype.setStateFromFluxRecord = function(stateField, fluxRecord, initialFluxRecord, key) {
          var data, modelName, progress, ref2, ref3, ref4, reloadAt, status, tryCount;
          if ((fluxRecord != null ? fluxRecord.status : void 0) !== success && (initialFluxRecord != null ? initialFluxRecord.status : void 0) === success) {
            fluxRecord = initialFluxRecord;
          }
          if (stateField && isFunction(this.setState)) {
            if (fluxRecord) {
              status = (ref2 = fluxRecord.status) != null ? ref2 : null, progress = (ref3 = fluxRecord.progress) != null ? ref3 : null, data = (ref4 = fluxRecord.data) != null ? ref4 : null;
            }
            this.setState(stateField, data);
            this.setState(stateField + "Key", key != null ? key : fluxRecord.key);
            this.setState(stateField + "Status", status);
            this.setState(stateField + "Progress", progress);
            this.setState(stateField + "FailureInfo", fluxRecord && isFailure(status) ? ((reloadAt = fluxRecord.reloadAt, tryCount = fluxRecord.tryCount, modelName = fluxRecord.modelName, key = fluxRecord.key, fluxRecord), {
              reloadAt: reloadAt,
              tryCount: tryCount,
              status: status,
              retryNow: getRetryNow(modelName, key)
            }) : null);
          }
          return fluxRecord;
        };

        return FluxSubscriptionsMixin;

      })(superClass);
    };
  });

}).call(this);

//# sourceMappingURL=FluxSubscriptionsMixin.js.map
