unless self.AWS
  throw new Error """
    Art.Aws: global.AWS required

    Please use one of the following:

      > require 'art-aws/Client'
      > require 'art-aws/Server'
    """
module.exports = [
  require './Config'
  require './DynamoDb'
]
