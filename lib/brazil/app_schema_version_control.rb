
require 'rio'
require 'httpclient'
require 'digest/md5'

require 'brazil/schema_revision'
require 'brazil/version_control/svn_cli'

module Brazil
  class AppSchemaVersionControl
  
    TYPE_SUBVERSION = :svn
  
    def initialize(arg_hash)
      @vc_type = arg_hash[:vc_type]
      @vc_uri = arg_hash[:vc_uri]
      @vc_path = arg_hash[:vc_path].gsub(/(.*?)\/$/, "\\1")
      @vc_password = arg_hash[:vc_password]
      @vc_user = arg_hash[:vc_user]
      @vc_tmp_dir = arg_hash[:vc_tmp_dir]
      
      unless @vc_type && @vc_uri && @vc_path
        raise ArgumentException, 'Missing mandatory argument!' 
      end
    end
  
    def find_schemas
      case @vc_type
        when TYPE_SUBVERSION then
          clnt = HTTPClient.new
          vc_schema_html = clnt.get_content("#{@vc_uri}#{@vc_path}")
         
          schemas = []
          vc_schema_html.scan(/>([\w\d_-]+)\/<\/a><\/li>/) do |schema|
            schemas << schema[0]
          end
      
          return schemas.sort!
        else
          raise AppSchemaVersionControlException, "no such version control type available"
      end
    end  
  
    def find_next_schema_version schema
      case @vc_type
        when TYPE_SUBVERSION then
          versions = find_versions(schema).reverse!
    
          if versions.count == 0
            return 
          end  
      
          return versions[0].next.to_s
        else
          raise AppSchemaVersionControlException, "no such version control type available"
      end
    end
    
    def find_versions schema
      case @vc_type
        when TYPE_SUBVERSION then
          begin 
            clnt = HTTPClient.new
            vc_schema_html = clnt.get_content("#{@vc_uri}#{@vc_path}/#{schema}/#{find_schema_type(schema)}")
         rescue HTTPClient::BadResponseError => e
           # enjoy the silence
           vc_schema_html = ""
         end
         
          versions = []
          vc_schema_html.scan(/-(\w+_\w+_\w+)-update.sql"/) do |version|
            versions << Brazil::SchemaRevision::from_string(version[0])
          end
      
          return versions.sort!
        else
          raise AppSchemaVersionControlException, "no such version control type available"
      end
    end    
  
    def find_schema_type schema
      case @vc_type
        when TYPE_SUBVERSION then
          clnt = HTTPClient.new
          vc_schema_type_html = clnt.get_content("#{@vc_uri}#{@vc_path}/#{schema}")
          type = vc_schema_type_html[/>([\w\d_-]+)\/<\/a><\/li>/]
          return $1
        else
          raise AppSchemaVersionControlException, "no such version control type available"
      end
    end
  
    def vc_working_copy
      vc
      @vc_working_copy
    end
  
    def vc
      unless @vc_tmp_dir
        raise ArgumentException, 'Temp directory argument not set, cannot initialize working copy' 
      end
      
      unless @vc_working_copy 
        case @vc_type
          when TYPE_SUBVERSION then
            version_repos_path = "#{@vc_uri}#{@vc_path}"
            @vc = Brazil::VersionControl::SvnCli.new(version_repos_path, @vc_user, @vc_password)
            unless @vc.valid_credentials?
              raise Brazil::VersionControlException, "version control username or password are not correct"
            end
            
            @vc_working_copy = rio(@vc_tmp_dir, Digest::MD5.hexdigest(@vc_path))
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
end