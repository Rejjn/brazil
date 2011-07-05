require 'dbi'

module VersionsHelper
  
  def state_text version
    if version.deployed?
      'Deployed'    
    elsif version.uploaded?
      'Uploaded'
    elsif version.tested?
      'Tested Oki'
    elsif version.update_tested?
      'Rollback tested'
    elsif version.rollback_tested?
      'Update tested'
    else
     'Created' 
    end
  end
  
  def state_class version
      
    if version.deployed?
      'deployed'
    elsif version.uploaded?
      'uploaded'
    elsif version.tested?
      'tested'
    else
      'created'
    end
  end
  
  def version_state_img version, type
    case type
      when :update
        if version.update_tested?
          image_tag '/images/tick.png', :class => 'version_test_status'
        else
          image_tag '/images/cross.png', :class => 'version_test_status'
        end
      when :rollback
        if version.rollback_tested?
          image_tag '/images/tick.png', :class => 'version_test_status'
        else
          image_tag '/images/cross.png', :class => 'version_test_status'
        end
      when :uploaded
        if version.uploaded?
          image_tag '/images/tick.png', :class => 'version_test_status'
        else
          image_tag '/images/cross.png', :class => 'version_test_status'
        end
      when :deployed
        if version.deployed?
          image_tag '/images/tick.png', :class => 'version_test_status'
        else
          image_tag '/images/cross.png', :class => 'version_test_status'
        end
    end  
  end


end
