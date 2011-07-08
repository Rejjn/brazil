
require 'open4'

require 'brazil/version_control/svn_generic'

module Brazil
  module VersionControl
  class SvnCli < SVNGeneric

    SVN_BIN = ::AppConfig.svn_bin

    def initialize(repository_uri, username, password)
      
      puts "init svn cli: #{[repository_uri, username, password].inspect}"
      
      @repository_uri = repository_uri
      @username = username
      @password = password
    end

    def checkout(checkout_path, vc_revision=nil)
      repos_path = make_revision_path(vc_revision)
      begin
        pid, stdin, stdout, stderr = Open4.popen4("#{svn_bin} checkout #{repos_path} #{rev_opts} #{checkout_path}")
        ignored, status = Process::waitpid2 pid
        
        raise Brazil::Error, "Failed checkout #{repos_path}@#{vc_revision} to #{checkout_path}, #{stderr.read}" if status.exitstatus != 0  
      rescue Brazil::Error => cli_exception
        raise Brazil::VersionControlException, "Could not checkout repository: #{@repository_uri} to path: #{checkout_path} (#{cli_exception})", caller
      end
    end

    def export(export_path, vc_revision=nil)
      raise Brazil::VersionControlException, "API function 'export' not yet implemented!", caller
#      repos_path = make_revision_path(vc_revision)
#      begin
#        vc_client.export(repos_path, export_path, nil)
#      rescue Brazil::Error => cli_exception
#        raise Brazil::VersionControlException, "Could not export repository: #{@repository_uri} to path: #{export_path} (#{cli_exception})", caller
#      end
    end

    def update(working_copy_path)
      raise Brazil::VersionControlException, "The working copy dir #{working_copy_path} does not exist!" unless File.directory? working_copy_path

      begin
        pid, stdin, stdout, stderr = Open4.popen4("#{svn_bin} update #{working_copy_path}")
        ignored, status = Process::waitpid2 pid
        
        #raise Brazil::Error, "Failed update working copy #{working_copy_path}, #{stderr.gets}" if wait_thr.value.exitstatus != 0
            
        if stdout.read =~ /^Skipped/         
          raise Brazil::Error, "Skipped #{working_copy_path}, most likely not a working copy, #{stdout.read}"
        end
      rescue Brazil::Error => cli_exception
        raise Brazil::VersionControlException, "Could not update working copy path: #{working_copy_path} (#{cli_exception})", caller
      end
    end

    def get_property(relative_repos_path, property_name, vc_revision=nil)
      raise Brazil::VersionControlException, "API function 'get_property' not yet implemented!", caller
#      repos_path = make_revision_path(vc_revision, relative_repos_path)
#      begin
#        return vc_client.revprop_get(property_name, repos_path)
#      rescue Svn::Error => svn_exception
#        raise Brazil::VersionControlException, "Could not get property: #{property_name} on url: #{repos_path}@#{vc_revision.to_s} (#{svn_exception})", caller
#      end
    end

    def set_property(relative_repos_path, property_name, property_value, vc_revision=nil)
      raise Brazil::VersionControlException, "API function 'set_property' not yet implemented!", caller
#      repos_path = make_revision_path(vc_revision, relative_repos_path)
#      begin
#        vc_client.revprop_set(property_name, property_value, repos_path, nil, false)
#      rescue Svn::Error => svn_exception
#        raise Brazil::VersionControlException, "Could not set property: #{property_name} on url: #{repos_path}@HEAD (#{svn_exception})", caller
#      end
    end

    def add(working_copy_paths)
      working_copy_paths = make_arg_array working_copy_paths
      valid_paths? working_copy_paths
      
      begin
        pid, stdin, stdout, stderr = Open4.popen4("#{svn_bin} add #{working_copy_paths.join(' ')}")
        ignored, status = Process::waitpid2 pid
        
        raise Brazil::Error, "Failed to add #{working_copy_paths.join(',')} to working copy, #{stderr.read}" if status.exitstatus != 0
      rescue Brazil::Error => svn_exception
        raise Brazil::VersionControlException, "Could not add to working copy (#{svn_exception})", caller
      end
    end

    def delete(working_copy_paths)
      working_copy_paths = make_arg_array working_copy_paths
      valid_paths? working_copy_paths

      begin
        pid, stdin, stdout, stderr = Open4.popen4("#{svn_bin} del #{working_copy_paths.join(' ')}")
        ignored, status = Process::waitpid2 pid

        raise Brazil::Error, "Failed to delete #{working_copy_paths.join(',')} from working copy, #{stderr.read}" if status.exitstatus != 0
      rescue Brazil::Error => svn_exception
        raise Brazil::VersionControlException, "Could not delete from working copy (#{svn_exception})", caller
      end
    end

    def commit(working_copy_paths, commit_message)
      working_copy_paths = make_arg_array working_copy_paths
      valid_paths? working_copy_paths
      
      begin
        pid, stdin, stdout, stderr = Open4.popen4("#{svn_bin} commit -m '#{commit_message}' #{working_copy_paths.join(' ')}")
        ignored, status = Process::waitpid2 pid
        
        raise Brazil::Error, "Failed to commit #{working_copy_paths.join(',')} to working copy, #{stderr.read}" if status.exitstatus != 0
      rescue Brazil::Error => svn_exception
        raise Brazil::VersionControlException, "Could not commit to working copy (#{svn_exception})", caller
      end
    end

    def valid_credentials?
      # can only check (write) credentials with commit it seems...
      true       
    end

    protected
    
    def make_arg_array arg
      arg = arg.values if arg.class == Hash
      arg = [arg] if arg.class != Array
      arg
    end
    
    def valid_paths? working_copy_paths
      working_copy_paths.each do |path|
        raise Brazil::VersionControlException, "The path #{path} does not exist!" if !(File.directory?(path) || File.file?(path))  
      end
      working_copy_paths
    end
    
    def svn_bin
      "#{SVN_BIN} #{general_opts} #{user_opts}"
    end
    
    def user_opts
        "--username #{@username} --password #{@password} --no-auth-cache"
    end

    def general_opts
      "--non-interactive"    
    end

    def rev_opts(revision=nil)
      "--revision #{revision}" if revision
    end
  

    def set_commit_message(commit_message)
      raise Brazil::VersionControlException, "API function 'set_commit_message' not yet implemented!", caller
#      begin
#        vc_client.set_log_msg_func do |items|
#          [true, commit_message]
#        end
#      rescue Svn::Error => svn_exception
#        raise Brazil::VersionControlException, "Could not set commit message: #{commit_message} in repository: #{@repository_uri} (#{svn_exception})", caller
#      end
    end

    def repos_list(repos_path, recurse, &block) # :yields: VersionControl::Path
      raise Brazil::VersionControlException, "API function 'repos_list' not yet implemented!", caller
#      begin
#        vc_client.list(repos_path, nil, nil, recurse, nil, true) do |path, dirent, lock, abs_path|
#          vc_path = make_vc_path(repos_path, path, dirent)
#          yield vc_path unless vc_path.path == ''
#        end
#      rescue Svn::Error => svn_exception
#        raise Brazil::VersionControlException, "Could not list: #{repos_path} (#{svn_exception})", caller
#      end
    end

    def repos_cat(repos_path)
      raise Brazil::VersionControlException, "API repos_cat 'export' not yet implemented!", caller
#      begin
#        return vc_client.cat(repos_path, nil)
#      rescue Svn::Error => svn_exception
#        raise Brazil::VersionControlException, "Could not cat: #{repos_path}@HEAD (#{svn_exception})", caller
#      end
    end

    def repos_copy(vc_revision, commit_message='')
      raise Brazil::VersionControlException, "API function 'repos_copy' not yet implemented!", caller
#      set_commit_message(commit_message)
#      destination_uri = make_revision_path(vc_revision)
#
#      begin
#        vc_client.copy(@repository_uri, destination_uri, nil)
#      rescue Svn::Error => svn_exception
#        raise Brazil::VersionControlException, "Could not tag/branch: #{vc_revision.id} in module: #{destination_uri} (#{svn_exception})", caller
#      end
    end

    def make_vc_path(repository_path, path, dirent)
      vc_path = Path.new
      vc_path.path = path

      vc_path.uri = repository_path
      vc_path.uri += '/' + path unless path == ''

      vc_path.file = dirent.file?
      vc_path.directory = dirent.directory?
      vc_path.revision = dirent.created_rev
      vc_path.size = dirent.size
      vc_path.author = dirent.last_author
      return vc_path
    end
  end
  end
end