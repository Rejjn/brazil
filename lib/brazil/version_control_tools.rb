
require 'rio'
require 'httpclient'
require 'cobravsmongoose'

require 'brazil/schema_revision'
require 'brazil/version_control'

module Brazil
  class VersionControlTools
  
    attr_reader :vc
    attr_reader :vc_working_copy
  
    TYPE_SVN = 'svn'
  
    def configure(vc_type, vc_uri, vc_path, vc_user, vc_password, vc_tmp_dir)
      @vc_type = vc_type
      @vc_uri = vc_uri
      @vc_path = vc_path.gsub(/(.*?)\/$/, "\\1")
      @vc_password = vc_password
      @vc_user = vc_user
      @vc_tmp_dir = vc_tmp_dir
      @vc_configured = true
    end
  
    def find_next_schema_version
      schema_version = nil
      
      case @vc_type
        when TYPE_SVN then
          clnt = HTTPClient.new
          vc_schema_html = clnt.get_content("#{@vc_uri}#{@vc_path}")
         
          puts vc_schema_html.inspect
         
          versions = []
          vc_schema_html.scan(/-(\w+_\w+_\w+)-update.sql"/) do |version|
            versions << Brazil::SchemaRevision::from_string(version[0])
          end
          
          versions.sort!.reverse!  
    
          if versions.count == 0
            return 
          end  
      
          return versions[0].next.to_s
        else
          raise Brazil::VersionControlException, "no such version control type available"
      end
    end
  
    def init_vc
      case @vc_type
        when TYPE_SVN then
      
          version_repos_path = "#{@vc_uri}#{@vc_path}"
          @vc = Brazil::VersionControl.new(@vc_type, version_repos_path, @vc_user, @vc_password)
          unless @vc.valid_credentials?
            raise Brazil::VersionControlException, "version control username or password are not correct"
          end
          
          @vc_working_copy = rio(@vc_tmp_dir, @vc_path)
          if @vc_working_copy.directory?
            @vc.update(@vc_working_copy.path)
          else
            @vc.checkout(@vc_working_copy.path)
          end
        else
          raise Brazil::VersionControlException, "no such version control type available"
      end
    end  
  end
end