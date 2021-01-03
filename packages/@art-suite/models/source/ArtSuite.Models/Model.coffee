{
  log, decapitalize, merge, isString
  compactFlatten
  Promise
  formattedInspect
  isPlainObject
  ErrorWithInfo
  defineModule
} = require "art-standard-lib"
{BaseObject} = require 'art-class-system'
{InstanceFunctionBindingMixin} = require "@art-suite/instance-function-binding-mixin"

{missing, success, pending, failure, validStatus, isFailure} = require 'art-communication-status'
{store} = require "./Store"
ModelRegistry = require './ModelRegistry'


defineModule module, class Model extends InstanceFunctionBindingMixin BaseObject
  @abstractClass()

  @declarable
    staleDataReloadSeconds:         null # if >0, reload stale data as soon as its older than this number in seconds
    minNetworkFailureReloadSeconds: null # if >0, and isFailure(fluxRecord.status) is true, that record well get a model.reload(key) call within this number of seconds after the failure
    maxNetworkFailureReloadSeconds: Infinity # repeated failed reloads retry with exponential fall offs; this caps the max interval for retrying
    minServerFailureReloadSeconds:  null # if >0, and isFailure(fluxRecord.status) is true, that record well get a model.reload(key) call within this number of seconds after the failure
    maxServerFailureReloadSeconds:  Infinity # repeated failed reloads retry with exponential fall offs; this caps the max interval for retrying

  @getter
    autoReloadEnabled: ->
      @getStaleDataReloadSeconds() > 0 ||
      @getMinNetworkFailureReloadSeconds() > 0 ||
      @getMinServerFailureReloadSeconds() > 0

  # must call register to make model accessable to RestComponents
  # NOTE: @fields calls register for you, so if you use @fields, you don't need to call @register
  @register: ->
    @singletonClass()
    ModelRegistry.register @getSingleton()

  @postCreateConcreteClass: ({hotReloaded}) ->
    if hotReloaded
      @singleton.bindFunctionsToInstance()
    else
      @register()
    super

  ###
  INPUT: zero or more strings or arrays of strings
    - arbitrary nesting of arrays is OK
    - nulls are OK, they are ignored
  OUTPUT: null

  NOTE: @aliases can be called multiple times.

  example:
    class Post extends Model
      @aliases "chapterPost"

  purpose:
    - declare alternative names to access this model.
    - allows you to use the shortest form of FluxComponent subscriptions for each alias:
        @subscriptions "chapterPost"
      in addition to the model's class name:
        @subscriptions "post"
  ###
  @aliases: (args...) ->
    @_aliases = compactFlatten [args, @_aliases]
    null

  @_aliases: []

  onNextReady: (f) -> store.onNextReady f

  constructor: (name)->
    super
    @_name = name || decapitalize @class.getName()
    @bindFunctionsToInstance()
    @_activeLoadingRequests = {}

  @classGetter
    models: -> ModelRegistry.models
    store: -> store

  @getter
    models: -> ModelRegistry.models
    store: -> store
    singlesModel: -> @_singlesModel || @
    storeEntries: -> store.getEntriesForModel @name

  # DEPRICATED
  subscribe: (fluxKey, subscriptionFunction) ->
    log.error "DEPRICATED - use ModelSubscriptionsMixin and it's subscribe"
    store.subscribe @_name, fluxKey, subscriptionFunction

  @getter "name",
    modelName: -> @_name

  ### load:
    load the requested data for the given key and update the store

    required:
      Should ALWAYS call store.update immediately OR once the data is available.
      Clients will assume that a call to "load" forces a reload of the data in the store.

    optional:
      If the data is immediately available, you can return the fluxRecord instead of "null"
      If load was called because of a new Component being mounted and its subscriptions initialized,
        returning the fluxRecord immediately will guarantee the Component has valid data for its
        first render.

    Note:
      Typically called automatically by the store when a Component subscribes to
      data from this model with the given key.

    The simplest possible load function:
      load: (key) -> @updateStore key, {}

    The "load" function below is:
      Simplest "load" with immediate fluxRecord return.
      Immediate return means:
      - store.subscribe() will return the fluxRecord returned from this "load"
      - FluxComponent subscriptions will update state in time for the inital render.

    inputs:
      key: string

    side effects:
      expected to call store.update @_name, key, fluxRecord
        - when fluxRecord.status is no longer pending
        - optionally as progress is made loading the fluxRecord.data

    returns: null OR fluxRecord if the value is immediately available
      NOTE: load can return null or fluxRecord as it chooses. The client shouldn't
        rely on the fact that it returned a fluxRecord with a set of inputs, it might not
        the next time.

    Optionally, you can implement one of two altenative load functions with Promise support:

      loadData:       (key) ->
                        promise.then (data) ->
                          if data is null or undefined, status will be set to missing
                          otherwise, status will be success
                        promise.catch (a validStatus or error info, status becomes failure) ->
      loadFluxRecord: (key) -> promise.then (fluxRecord) ->

      @load will take care of updating Store.
  ###
  load: (key) ->
    # ensure store is updated in case this is not beind called from the store itself
    # returns {status: missing} since updateStore returns the last argument,
    #   this makes the results immediately available to subscribers.

    if @loadData || @loadFluxRecord
      @loadPromise key
      null
    else
      @updateStore key, status: missing

  ### loadPromise:
    NOTE: @loadData or @loadFluxRecord should be implemented.
    @loadPromise is an alternative to @load

    Unlike @load, @loadPromise returns a promise that resolves when the load is done.

    The down-side is @loadPromise cannot immediately update the flux-store. If you have
    a model which stores its data locally, like ApplicationState, then override @load
    for immediate store updates.

    However, if your model always has to get the data asynchronously, override @loadData
    or @loadFluxRecord and use @loadPromise anytime you need to manually trigger a load.

    EFFECTS:
    - Triggers loadData or loadFluxRecord.
    - Puts the results in the store.
    - Elegently reduces multiple in-flight requests with the same key to one Promise.
      @loadData or @loadFluxRecord will only be invoked once per key while their
      returned promises are unresolved.
      NOTE: the block actually extends all the way through to the store being updated.
      That means you can immediately call @storeGet and get the latest data - when
      the promise resolves.

    OUT: promise.then (fluxRecord) ->
      fluxRecord: the latest, just-loaded data
      ERRORS: errors are encoded into the fluxRecord. The promise should always resolve.
  ###
  loadPromise: (key) ->
    if p = @_activeLoadingRequests[key]
      # log "saved 1 reload due to activeLoadingRequests! (model: #{@name}, key: #{key})"
      return p

    p = if @loadData
      Promise.then    => @loadingRecord key
      .then           => @loadData key
      .then (data)    => @updateStore key, if data? then status: success, data: data else status: missing
      .catch (error)  =>
        status = if validStatus status = error?.info?.status || error
          status
        else failure
        info = error?.info
        error = null unless error instanceof Error
        @updateStore key, {status, info, error}

    else if @loadFluxRecord
      @loadFluxRecord key
      .then (fluxRecord) => @updateStore key, fluxRecord
      .catch (error)     => @updateStore key, status: failure, error: error
    else
      Promise.resolve @updateStore key, status: missing

    @_activeLoadingRequests[key] = p
    .then (result) => @onNextReady(); result
    .then (result) => @_activeLoadingRequests[key] = null; result

  # load is not required to updateStore
  # reload guarantees store is updated
  # override reload if your load does not always updateStore (eventually)
  reload: (key) ->
    if @loadData || @loadFluxRecord
          @loadPromise key
    else  @load key

  # called before actually calling @loadData within @loadPromise
  # EFFECT: marks record status as pending if it was previously a failure
  #   If it was previously a success, subscribers should keep showing the previously
  #   successful load until the new one completes.
  loadingRecord: (key) ->
    if isFailure (fluxRecord = @storeGet key)?.status
      @updateStore key, merge fluxRecord, status: pending

  storeGet:     (key) -> store.get @_name, @toKeyString key
  updateStore:  (key, fluxRecord) -> store.update @_name, key, fluxRecord

  onModelRegistered: (modelName) -> ModelRegistry.onModelRegistered modelName

  # IN: key
  # OUT: promise.then data
  # EFFECT: if already loaded in store, just returns what's in fluxstore
  get: (key) ->
    key = @toKeyString key
    Promise.then =>
      if (currentFluxRecord = @storeGet(key))?.status == pending
        currentFluxRecord = null

      currentFluxRecord ? @loadPromise key

    .then (fluxRecord)->
      {status, data} = fluxRecord
      unless status == success
        throw new ErrorWithInfo "Model#get: Error getting data. Status: #{status}.", {status, fluxRecord}

      data

  # Override to support non-string keys
  # return: string representation of key
  toKeyString: (key) ->
    if isPlainObject key then @dataToKeyString key
    else if isString key then key
    else
      throw new Error "Model #{@name}: Must implement
        custom toKeyString for
        non-string keys like: #{formattedInspect key}"

  dataToKeyString: (obj) ->
    throw new Error "Model #{@name}: must override dataToKeyString for converting objects to key-strings."

  @getRecordPropsToKeyFunction: (recordType) ->
    (props, stateField) =>
      propsField = stateField ? recordType
      props[propsField]?.id ? props[propsField + "Id"]

  @getter
    propsToKey: -> @_propsToKey ?= Model.getRecordPropsToKeyFunction @modelName

  ###################################################
  # OVERRIDES
  ###################################################
  # Override to respond to entries being added or removed from the flux-store

  # called when an entry is updated OR added OR if it is about to be removed
  # this is called before storeEntryAdded or storeEntryRemoved
  storeEntryUpdated: (entry) ->

  # called only when an entry is added
  storeEntryAdded: (entry) ->

  # called when an entry was moved (when subscriber count goes to 0)
  storeEntryRemoved: (entry) ->

  ###################################################
  # localStorage helper methods
  ###################################################

  _localStoreKey: (id) -> "model:#{@_name}:#{id}"

  _localStoreGet: (id) ->
    if data = localStorage.getItem @_localStoreKey id
      JSON.parse data
    else
      null

  _localStoreSet: (id, data) -> localStorage.setItem @_localStoreKey(id), JSON.stringify data
