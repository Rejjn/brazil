class App < ActiveRecord::Base
  has_many :activities, :order => 'updated_at DESC', :dependent => :destroy

  validates_presence_of :name, :vc_path
  validates_format_of :vc_path, :with => /^(\/[\w\d -]+)+$/

  def to_s
    name
  end
end
