
require 'rio'
require 'httpclient'
require 'cobravsmongoose'

require 'brazil/schema_revision'
require 'brazil/version_control'
require 'brazil/version_control_tools'

module Brazil
  class DeploySourceTools
  
    TYPE_SVN = 'svn'
    TYPE_BAMBOO = 'bamboo'
  
    attr_reader :version_control_tools
    
    def initialize()
      @version_control_tools = VersionControlTools.new
    end
  
    def configure(src_type, src_uri, src_path, src_user, src_password, src_tmp_dir)
      @src_uri = src_uri
      @src_type = src_type 
      @src_path = src_path
      @src_password = src_password
      @src_user = src_user
      @src_tmp_dir = src_tmp_dir
      @src_configured = true
      
      @version_control_tools.configure(src_type, src_uri, src_path, src_user, src_password, src_tmp_dir)
    end
  
    def find_versions
      init_src
      
      update_files = @src_working_copy.files['*-update.sql']
      
      versions = []
      update_files.each do |file|
        versions << Brazil::SchemaRevision::from_string(file.to_s.match(/-(\w+_\w+_\w+)-/)[1])
      end
      
      versions.sort!
    end
  
    def init_src 
      if @src_type == TYPE_SVN
        @version_control_tools.init_vc
        @src_working_copy = @version_control_tools.vc_working_copy
      else
        @src_working_copy = init_bamboo_src
      end
      
      @src_working_copy
    end
    
    def init_bamboo_src
      
    end
  end
end