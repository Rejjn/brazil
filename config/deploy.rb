set :application, "Brazil"
set :repository,  "git://github.com/Rejjn/brazil.git"

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`


set :branch do
  default_tag = `git tag`.split("\n").last

  tag = Capistrano::CLI.ui.ask "Tag to deploy (make sure to push the tag first): [#{default_tag}] "
  tag = default_tag if tag.empty?
  tag
end

set :user, 'root'
set :use_sudo, false

set :deploy_to, '/opt/brazil'

role :app, "192.168.18.127"
role :web, "192.168.18.127"
role :db, "192.168.18.127", :primary => true

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

after 'deploy:symlink' do 
  run "#{try_sudo} cp #{File.join(deploy_to,'rvm','.rvmrc')} #{File.join(release_path)}"
  run "#{try_sudo} rvm rvmrc trust #{File.join(release_path)}"
end

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  desc "Copy the .rvmrc file and set trust flag"
  task :setup_rvm do
    puts "MAMMA: " + release_path
  end
  
  task :start do ; end
  task :stop do ; end
  
  desc "Restart Passenger"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
 end