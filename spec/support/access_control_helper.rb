
class AccessControlHelper
  def self.real_actions controller_class 
    actions = controller_class.action_methods
    actions.delete('current_user')
    
    actions.delete_if do |action|
      action[0] == '_'
    end
    
    actions
  end
  
  def self.http_method(action, block)
    case action
      when 'destroy'
        return block.method(:delete)
      when 'update', 'create'
        return block.method(:post)
      else
        return block.method(:get)
    end
  end
end