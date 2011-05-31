require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'brazil/version_control/svn_cli'

describe Brazil::VersionControl::SvnCli do

  SVN_URI = 'http://prsvn.ongame.com/svn/repos/test/brazil/rspec/'
  SVN_READ_USER = ''
  SVN_READ_PASSWORD = ''
  SVN_WRITE_USER = 'ldap_svnbuildserver'
  SVN_WRITE_PASSWORD = 'Rfi9w09iZX'

  before(:each) do
    @wc_tmp = '/tmp/rspec/' + (0...8).map{65.+(rand(25)).chr}.join
  end

  after(:each) do
    FileUtils.rm_rf(@wc_tmp)
    @svn_cli = nil
  end

  describe "when creating a new SVN CLI instance" do
    it "should successfully return a SVN CLI object" do
      svn_cli = Brazil::VersionControl::SVNCLI.new('http://repository_uri/', 'username', 'password')
      svn_cli.class.should == Brazil::VersionControl::SVNCLI 
    end
  end
  
  describe "doing SVN checkout" do
    it "should give a working copy at that the given path if SVN URI is valid" do
      svn_cli = Brazil::VersionControl::SVNCLI.new(SVN_URI, SVN_READ_USER, SVN_READ_PASSWORD)
      svn_cli.checkout(@wc_tmp)
      
      File.directory?(@wc_tmp).should == true
      File.directory?(@wc_tmp + '/.svn').should == true
    end
    
    it "should result in an error and no working copy if SVN URI is invalid" do
      svn_cli = Brazil::VersionControl::SVNCLI.new('http://this.repository_uri/is/not/valid', SVN_READ_USER, SVN_READ_PASSWORD)
      expect { svn_cli.checkout(@wc_tmp)}.to raise_error Brazil::VersionControlException
      File.directory?(@wc_tmp).should == false
    end
  end

  describe "doing SVN update" do
    
    before(:all) do
      @not_wc = '/tmp/rspec/not_working_copy'
      Dir.mkdir @not_wc
      @svn_cli = Brazil::VersionControl::SVNCLI.new(SVN_URI, SVN_READ_USER, SVN_READ_PASSWORD)
    end
    
    after(:all) do
      FileUtils.rm_rf(@not_wc)
    end
    
    it "should give an error if working copy path does not exist" do
      expect { @svn_cli.update('/tmp/that/does/not/exist')}.to raise_error Brazil::VersionControlException
    end
    
    it "should give an error if path is not a working copy" do
      expect { @svn_cli.update(@not_wc) }.to raise_error Brazil::VersionControlException
    end
    
    it "should update the working copy if it is valid" do
      @svn_cli.checkout(@wc_tmp)
      @svn_cli.update(@wc_tmp)
    end
  end
  
  describe "doing SVN add" do

    before(:all) do
      @add_not_in_wc = '/tmp/rspec/add_file1'
      File.new(@add_not_in_wc, 'w') << 'asdfasdfasdfasdf'
      @svn_cli = Brazil::VersionControl::SVNCLI.new(SVN_URI, SVN_READ_USER, SVN_READ_PASSWORD)
    end
    
    after(:all) do
      FileUtils.rm_rf(@add_not_in_wc)
    end
    
    it "should give an error if added paths does not exist" do
      expect {@svn_cli.add('/tmp/that/does/not/exist')}.to raise_error Brazil::VersionControlException
      expect {@svn_cli.add(['/tmp/that/does/not/exist', '/tmp/another/path'])}.to raise_error Brazil::VersionControlException
    end
    
    it "should give an error if added paths is already added" do
      expect {@svn_cli.add("#{@wc_tmp}/file1")}.to raise_error Brazil::VersionControlException
      expect {@svn_cli.add(["#{@wc_tmp}/file2", "#{@wc_tmp}/file3"])}.to raise_error Brazil::VersionControlException
    end
    
    it "should give an error if added paths are not in a working copy" do
      expect {@svn_cli.add(@add_not_in_wc)}.to raise_error Brazil::VersionControlException
    end
    
    it "should add the paths to working copy" do
      @svn_cli = Brazil::VersionControl::SVNCLI.new(SVN_URI, SVN_READ_USER, SVN_READ_PASSWORD)
      @svn_cli.checkout(@wc_tmp)

      @add_in_wc1 = "#{@wc_tmp}/add_file1"
      File.new(@add_in_wc1, 'w') << 'asdfasdfasdfasdf1'
      @add_in_wc2 = "#{@wc_tmp}/add_file2"
      File.new(@add_in_wc2, 'w') << 'asdfasdfasdfasdf2'
      @add_in_wc3 = "#{@wc_tmp}/add_file3"
      File.new(@add_in_wc3, 'w') << 'asdfasdfasdfasdf3'
      
      @svn_cli.add(@add_in_wc1)
      @svn_cli.add([@add_in_wc2, @add_in_wc3])
    end
  end

  describe "doing SVN delete" do

    before(:all) do
      @add_not_in_wc = '/tmp/rspec/add_file1'
      File.new(@add_not_in_wc, 'w') << 'asdfasdfasdfasdf'
      @svn_cli = Brazil::VersionControl::SVNCLI.new(SVN_URI, SVN_READ_USER, SVN_READ_PASSWORD)
    end
    
    after(:all) do
      FileUtils.rm_rf(@add_not_in_wc)
    end
    
    it "should give an error if added paths does not exist" do
      expect {@svn_cli.delete('/tmp/that/does/not/exist')}.to raise_error Brazil::VersionControlException
      expect {@svn_cli.delete(['/tmp/that/does/not/exist', '/tmp/another/path'])}.to raise_error Brazil::VersionControlException
    end
    
    it "should give an error if added paths are not in working copy" do
      expect { @svn_cli.delete(@add_not_in_wc) }.to raise_error Brazil::VersionControlException
    end

    it "should give an error if added files does not exist in working copy" do
      @svn_cli.checkout(@wc_tmp)
    
      expect { @svn_cli.delete("#{@wc_tmp}/none_existent_file") }.to raise_error Brazil::VersionControlException
      expect { @svn_cli.delete(["#{@wc_tmp}/file2", "#{@wc_tmp}/none_existent_file3"]) }.to raise_error Brazil::VersionControlException
    end
    
    it "should delete the paths from a working copy" do
      @svn_cli.checkout(@wc_tmp)

      @svn_cli.delete("#{@wc_tmp}/file1")
      @svn_cli.delete(["#{@wc_tmp}/file2", "#{@wc_tmp}/file3"])
    end
    
    it "should give an error if the paths in working copy have already been deleted" do
      @svn_cli.checkout(@wc_tmp)

      @svn_cli.delete("#{@wc_tmp}/file1")
      expect { @svn_cli.delete("#{@wc_tmp}/file1") }.to raise_error Brazil::VersionControlException
    end
  end

  describe "doing SVN commit" do

    before(:all) do
      @add_not_in_wc = '/tmp/rspec/add_file1'
      File.new(@add_not_in_wc, 'w') << 'asdfasdfasdfasdf'
      @svn_cli = Brazil::VersionControl::SVNCLI.new(SVN_URI, SVN_READ_USER, SVN_READ_PASSWORD)
    end
    
    after(:all) do
      FileUtils.rm_rf(@add_not_in_wc)
    end
    
    it "should give an error if commit paths does not exist" do
      expect {@svn_cli.commit('/tmp/that/does/not/exist', 'Some message')}.to raise_error Brazil::VersionControlException
      expect {@svn_cli.commit(['/tmp/that/does/not/exist', '/tmp/another/path'], 'Some message')}.to raise_error Brazil::VersionControlException
    end
    
    it "should give an error if commit paths are not in a working copy" do
      expect { @svn_cli.commit(@add_not_in_wc, 'Some message') }.to raise_error Brazil::VersionControlException
    end

    it "should give an error if the committed paths does not exist in working copy" do
      @svn_cli.checkout(@wc_tmp)
    
      expect { @svn_cli.commit("#{@wc_tmp}/none_existent_file", 'Some message') }.to raise_error Brazil::VersionControlException
      expect { @svn_cli.commit(["#{@wc_tmp}/file2", "#{@wc_tmp}/none_existent_file3"], 'Some message') }.to raise_error Brazil::VersionControlException
    end

    it "should not give an error if the committed paths have already been committed" do
      @svn_cli.checkout(@wc_tmp)

      @svn_cli.commit("#{@wc_tmp}/file1", 'ROGUE Brazil SVN CLI lib tests')
      @svn_cli.commit("#{@wc_tmp}/file1", 'ROGUE Brazil SVN CLI lib tests')
    end
    
    describe "that is successfull" do
      it "should commit the paths to the repos" do
        svn_cli = Brazil::VersionControl::SVNCLI.new(SVN_URI, SVN_WRITE_USER, SVN_WRITE_PASSWORD)
        svn_cli.checkout(@wc_tmp)
        
        @new_files = {}
          ['new_file1', 'new_file2', 'new_file3'].each do |filename|
            @new_files[filename] = "#{@wc_tmp}/#{filename}"
            File.exists?(@new_files[filename]).should == false
            File.new(@new_files[filename], 'w') << 'asdfasdfasdfasdf' + filename
        end
        
        svn_cli.add(@new_files)        
        
        svn_cli.commit(@new_files['new_file1'], 'ROGUE Brazil SVN CLI lib tests')
        svn_cli.commit([@new_files['new_file2'], @new_files['new_file3']], 'ROGUE Brazil SVN CLI lib tests')

        # clean
        svn_cli.delete(@new_files)
        svn_cli.commit(@wc_tmp, 'ROGUE Brazil SVN CLI lib tests')
      end
    end
  end
end
