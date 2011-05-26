
class BasicAuthHelper
  
  def self.auth_string(user = 'ldap_svnbuildserver', password = 'Rfi9w09iZX')
    "Basic " + Base64::encode64("#{user}:#{password}")
  end
  
  
end