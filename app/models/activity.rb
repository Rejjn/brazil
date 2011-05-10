class Activity < ActiveRecord::Base
  STATE_DEVELOPMENT = 'development'
  STATE_VERSIONED = 'versioned'
  STATE_DEPLOYED = 'deployed'

  belongs_to :app
  has_many :versions, :dependent => :destroy
  has_many :changes, :order => "created_at ASC", :dependent => :destroy

  belongs_to :db_instance

  validates_associated :db_instance
  validates_presence_of :name, :schema, :dev_schema

  # FIXME: Add before_save check state

  named_scope :latest, lambda { |limit| {:order => 'updated_at DESC', :limit => limit} }

  def development!
    update_attribute(:state, STATE_DEVELOPMENT)
  end

  def development?
    (state == Activity::STATE_DEVELOPMENT)
  end

  def versioned?
    (state == Activity::STATE_VERSIONED)
  end

  def versioned!
    update_attribute(:state, STATE_VERSIONED)
  end

  def deployed!
    update_attribute(:state, STATE_DEPLOYED)
  end

  def vc_path
    "#{app.vc_path}/#{schema}/#{db_type.downcase}"
  end

  def to_s
    name
  end
end
