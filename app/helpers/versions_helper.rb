require 'dbi'

module VersionsHelper
  
  def state_text state
    ['Created', 'Update tested', 'Rollback tested', 'Tested Oki', 'Uploaded', 'Deployed'].at state    
  end
  
  def state_class state
    case state
      when Version::STATE_CREATED, Version::STATE_UPDATE_TESTED, Version::STATE_ROLLBACK_TESTED
        'created'
      when  Version::STATE_ALL_TESTED
        'tested'
      when Version::STATE_UPLOADED
        'uploaded'
      when Version::STATE_DEPLOYED
        'deployed'
    end          
  end
  
  def version_state state, type
    case type
      when :update
        if state == Version::STATE_ALL_TESTED || state == Version::STATE_UPDATE_TESTED
          image_tag '/images/tick.png', :class => 'version_test_status'
        else
          image_tag '/images/cross.png', :class => 'version_test_status'
        end
      when :rollback
        if state == Version::STATE_ALL_TESTED || state == Version::STATE_ROLLBACK_TESTED
          image_tag '/images/tick.png', :class => 'version_test_status'
        else
          image_tag '/images/cross.png', :class => 'version_test_status'
        end
      when :uploaded
        if state == Version::STATE_UPLOADED
          image_tag '/images/tick.png', :class => 'version_test_status'
        else
          image_tag '/images/cross.png', :class => 'version_test_status'
        end
      when :deployed
        if state == Version::STATE_DEPLOYED
          image_tag '/images/tick.png', :class => 'version_test_status'
        else
          image_tag '/images/cross.png', :class => 'version_test_status'
        end
    end  
  end

  def sql_escape(object)
    escaped_object = DBI::TypeUtil.convert(nil, object)
    if escaped_object
      escaped_object
    else
      "NULL"
    end
  end
end
