class RefactorVersions < ActiveRecord::Migration
  def self.up
    
    version_state = {}
    Version.all.each do |version| 
      version_state[version.id] = version.state
    end
    
    change_column :versions, :state, :integer
    
    version_state.each do |id, state|
      begin
        case state
          when 'created'
            Version.find(id).update_attribute(:state, Version::STATE_CREATED)  
          when 'tested'
            Version.find(id).update_attribute(:state, Version::STATE_CREATED | Version::STATE_UPDATE_TESTED | Version::STATE_ROLLBACK_TESTED | Version::STATE_UPLOADED)
          when 'deployed'
            Version.find(id).update_attribute(:state, Version::STATE_CREATED | Version::STATE_UPDATE_TESTED | Version::STATE_ROLLBACK_TESTED | Version::STATE_UPLOADED | Version::STATE_DEPLOYED)
          else
            Version.find(id).update_attribute(:state, Version::STATE_CREATED)
        end
      rescue
        #hum? just continue...
      end
    end
    
    drop_table :db_instance_versions
  end

  def self.down
    change_column :versions, :state, :string
    create_table :db_instance_versions, :id => false do |t|
      t.references :db_instance
      t.references :version
    end
  end
end
