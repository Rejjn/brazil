require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Brazil::DatabaseSchema do

  ORACLE_DB_HOST = 'oracle.vte.b2c/paddev'
  ORACLE_DB_PORT = '1521'
  ORACLE_DB_TYPE = Brazil::DatabaseSchema::TYPE_ORACLE
  ORACLE_DB_SCHEMA = 'ASDFSAD_P84'
  ORACLE_DB_USER = 'ASDFSAD_P84'
  ORACLE_DB_PASSWORD = 'ASDFSAD_P84'

  APP_VC_URL = '/dev/chronicle2/trunk/docs/INSTALL/db/'

  describe 'oracle integration'

    before(:each) do
      #Brazil::SerenityIntegration.new.wipe_schema ORACLE_DB_TYPE, :schema => ORACLE_DB_SCHEMA
      @db = Brazil::DatabaseSchema.new(ORACLE_DB_HOST, ORACLE_DB_PORT, ORACLE_DB_TYPE, ORACLE_DB_SCHEMA, ORACLE_DB_USER, ORACLE_DB_PASSWORD)
      @asvc = Brazil::AppSchemaVersionControl.new(:vc_type => Brazil::AppSchemaVersionControl::TYPE_SUBVERSION, :vc_path => APP_VC_URL, :vc_uri => ::AppConfig.vc_uri, :vc_tmp_dir => ::AppConfig.vc_dir)
    end

#    describe "updating database schema" do
#      it "should be successfull" do
#        @db.update_to_version(@asvc, 'CHRONICLE', '1_0_0')
#      end
#    end
    
    describe "getting version information" do
#      it "should return an empty array if no versions has been deployed" do
#        @db.version_information.should == []
#      end
#    
#      it "should return an array with one element if only deploying 1 version" do
#        @db.update_to_version(@asvc, 'CHRONICLE', '1_0_0')
#        @db.version_information.should == [Brazil::SchemaRevision.new(1, 0, 0)]
#      end
    
      it "should return an array with one element if only deploying 1 version" do
        #@db.update_to_version(@asvc, 'CHRONICLE', '1_0_6')
        @db.version_information.should == [Brazil::SchemaRevision.new(1, 0, 0),
                                          Brazil::SchemaRevision.new(1, 0, 1),
                                          Brazil::SchemaRevision.new(1, 0, 2),
                                          Brazil::SchemaRevision.new(1, 0, 3),
                                          Brazil::SchemaRevision.new(1, 0, 4),
                                          Brazil::SchemaRevision.new(1, 0, 5),
                                          Brazil::SchemaRevision.new(1, 0, 6)]
      end

  end  
end
