{
  log, BaseObject, decapitalize, pluralize, pureMerge, shallowClone, isString,
  emailRegexp, urlRegexp, isNumber, nextTick, capitalize, inspect, isFunction, pureMerge
  isoDateRegexp
  time
  globalCount
  compactFlatten
} = require "art.foundation"
{fluxStore} = require "./flux_store"
ModelRegistry = require './model_registry'

module.exports = class FluxModel extends BaseObject
  # must call register to make model accessable to RestComponents
  # NOTE: @fields calls register for you, so if you use @fields, you don't need to call @register
  @register: -> @singleton ||= ModelRegistry.register @
  @postCreate: (klass) ->
    @register()
    klass

  @aliases: ->
    @_aliases = compactFlatten arguments

  onNextReady: (f) -> fluxStore.onNextReady f

  constructor: (name)->
    super
    @_name = name || decapitalize @class.name

  @classGetter
    models: -> ModelRegistry.models
    fluxStore: -> fluxStore

  @getter
    models: -> ModelRegistry.models
    fluxStore: -> fluxStore
    singlesModel: -> @_singlesModel || @

  @propGetter "name"

  ###
  load the requested data for the given key and update the fluxStore

  required:
    Should ALWAYS call fluxStore.update immediately OR once the data is available.
    Clients will assume that a call to "load" forces a reload of the data in the fluxStore.

  optional:
    If the data is immediately available, you can return the fluxRecord instead of "null"
    If load was called because of a new Component being mounted and its subscriptions initialized,
      returning the fluxRecord immediately will guarantee the Component has valid data for its
      first render.

  Note:
    Typically called automatically by the fluxStore when a Component subscribes to
    data from this model with the given key.

  The simplest possible load function:
    load: (key) -> @updateFluxStore key, {}

  The "load" function below is:
    Simplest "load" with immediate fluxRecord return.
    Immediate return means:
     - fluxStore.subscribe() will return the fluxRecord returned from this "load"
     - FluxComponent subscriptions will update state in time for the inital render.

  inputs:
    key: string

  side effects:
    expected to call fluxStore.update @_name, key, fluxRecord
      - when fluxRecord.status is no longer "pending"
      - optionally as progress is made loading the fluxRecord.data

  returns: null OR fluxRecord if the value is immediately available
    NOTE: load can return null or fluxRecord as it chooses. The client shouldn't
      rely on the fact that it returned a fluxRecord with a set of inputs, it might not
      the next time.
  ###
  load: (key) ->
    # ensure fluxStore is updated in case this is not beind called from the fluxStore itself
    # returns {status: 404} since updateFluxStore returns the last argument,
    #   this makes the results immediately available to subscribers.
    @updateFluxStore key, status: 404

  # load is not required to updateFluxStore
  # reload guarantees fluxStore is updated
  # override reload if your load does not always updateFluxStore (eventually)
  reload: (key) ->
    @load key

  # shortcut for updating the fluxStore for the current model
  updateFluxStore: (key, fluxRecord) -> fluxStore.update @_name, key, fluxRecord

  # Override to support non-string keys
  # return: string representation of key
  toFluxKey: (key) ->
    throw "FluxModel #{@name}: Must implement custom toFluxKey for non-string fluxKeys like: #{inspect key}" unless isString key
    key

  # Override to respond to entries being added or removed from the flux-store

  # called when an entry is updated OR added OR if it is about to be removed
  # this is called before fluxStoreEntryAdded or fluxStoreEntryRemoved
  fluxStoreEntryUpdated: (entry) ->

  # called only when an entry is added
  fluxStoreEntryAdded: (entry) ->

  # called when an entry was moved (when subscriber count goes to 0)
  fluxStoreEntryRemoved: (entry) ->

  ###
  localStorage helper methods
  ###

  _localStoreKey: (id) ->
    "fluxModel:#{@_name}:#{id}"

  _localStoreGet: (id) ->
    if data = localStorage.getItem @_localStoreKey id
      JSON.parse data
      # Scanning and parsing through to find dates is too slow (adds about 1ms of processing per frame)
      # Most the time we don't even care, so I put it up to the consumer to check if dates are dates or strings.
      # JSON.parse data, (key, value) ->
      #   if isString(value) && value.match isoDateRegexp
      #     new Date value
      #   else
      #     value
    else
      null

  # TODO: We need a way to expire old items
  _localStoreSet: (id, data) ->
    # log "_localStoreSet: #{@_localStoreKey id}", data
    localStorage.setItem @_localStoreKey(id), JSON.stringify data
