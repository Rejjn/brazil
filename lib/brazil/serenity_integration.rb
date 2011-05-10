require 'httpclient'
require 'cobravsmongoose'

module Brazil
  class SerenityIntegration  
    
      # identifiers is an array, use:
      # :schema for oracle databases
      # :port for mysql
      def wipe_schema db_type, identifiers
      clnt = HTTPClient.new
      response = nil
      
      case db_type
        when DatabaseSchema::TYPE_ORACLE then
          response = clnt.put("#{::AppConfig.serenity_url}#{::AppConfig.serenity_clean_action}/#{identifiers[:schema]}.xml")
        when DatabaseSchema::TYPE_MYSQL then
          response = clnt.put("#{::AppConfig.serenity_url}#{::AppConfig.serenity_clean_action}/mysql:#{identifiers[:port]}.xml")
      end
      doc = CobraVsMongoose.xml_to_hash(response.content)
      
      if !(defined? doc['hash']) || !(doc['hash']['status']['$'] == 'success')
        raise RemoteAPIException, 'failed to clean database - ' << doc["hash"]["message"]['$']
      end
    end
  end
end