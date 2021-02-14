// Generated by CoffeeScript 1.12.7
(function() {
  var Config, Configurable, defineModule, formattedInspect, log, merge, mergeInto, newObjectFromEach, objectHasKeys, ref, select,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  ref = require('art-standard-lib'), merge = ref.merge, log = ref.log, objectHasKeys = ref.objectHasKeys, formattedInspect = ref.formattedInspect, defineModule = ref.defineModule, select = ref.select, newObjectFromEach = ref.newObjectFromEach, mergeInto = ref.mergeInto;

  Configurable = require('art-config').Configurable;

  defineModule(module, Config = (function(superClass) {
    var awsServiceToConfigNameMap;

    extend(Config, superClass);

    function Config() {
      return Config.__super__.constructor.apply(this, arguments);
    }

    Config.defaults({
      credentials: {
        accessKeyId: 'blah',
        secretAccessKey: 'blah'
      },
      region: 'us-east-1',
      s3Buckets: {},
      dynamoDb: {
        maxRetries: 5
      },
      sqs: {
        queueUrlPrefix: null
      }
    });

    Config.awsServiceToConfigNameMap = awsServiceToConfigNameMap = {
      es: "elasticsearch"
    };


    /*
      Search order:
        @config[service].credentials
        @config[awsServiceToConfigNameMap[service]].credentials
        @config.credentials
     */

    Config.getAwsCredentials = function(service) {
      var ref1;
      return ((ref1 = Config.getAwsServiceConfig(service)) != null ? ref1.credentials : void 0) || Config.config.credentials;
    };

    Config.getAwsServiceConfig = function(service) {
      return Config.config[service] || Config.config[awsServiceToConfigNameMap[service]];
    };

    Config.getNormalizedConfig = function(forService, options) {
      var config, defaultCredentials, rawServiceConfig;
      defaultCredentials = Config.getDefaultConfig().credentials;
      rawServiceConfig = Config.getAwsServiceConfig(forService);
      config = merge({
        accessKeyId: Config.config.credentials.accessKeyId,
        secretAccessKey: Config.config.credentials.secretAccessKey,
        region: Config.config.region,
        maxRetries: 5
      }, rawServiceConfig != null ? rawServiceConfig.credentials : void 0, rawServiceConfig, options);
      if (config.accessKeyId === defaultCredentials.accessKeyId && !config.endpoint) {
        log.error("Art.Aws invalid configuration for " + forService + ".\n\nPlease set one of:\n- Art.Aws.credentails for connection to AWS\n- Art.Aws." + forService + ".endpoint for connection to a local server.\n\n" + (options && objectHasKeys(options) ? formattedInspect({
          "Art.Aws.config": Config.config,
          options: options,
          "merged config": config
        }) : formattedInspect({
          "Art.Aws.config": Config.config,
          "merged config": config
        })) + "\n");
        throw new Error("invalid config options");
      }
      return config;
    };

    return Config;

  })(Configurable));

}).call(this);

//# sourceMappingURL=Config.js.map