module ApplicationHelper
  
  def javascripts
    javascript_tags = ''
    if File.exists? "#{Rails.root.to_s}/public/javascripts/#{params[:controller]}.js"
      javascript_tags << javascript_include_tag("#{params[:controller]}")
    end
    if File.exists? "#{Rails.root.to_s}/public/javascripts/#{params[:controller]}/#{params[:action]}.js"
      javascript_tags << javascript_include_tag("#{params[:controller]}/#{params[:action]}")
    end
    javascript_tags
  end

  def stylesheets
    link_tags = ''
    if File.exists? "#{Rails.root.to_s}/public/stylesheets/#{params[:controller]}.css"
      link_tags << stylesheet_link_tag("#{params[:controller]}", :media => "screen, projection")
    end
    if File.exists? "#{Rails.root.to_s}/public/stylesheets/#{params[:controller]}/#{params[:action]}.css"
      link_tags << stylesheet_link_tag("#{params[:controller]}/#{params[:action]}", :media => "screen, projection")
    end
    link_tags
  end
  
  def generate_title(crumbs)
    title = ''
    crumbs[1..-1].each do |crumb|
      title += crumb.first.to_s
      unless crumb == crumbs.last
        title += ' > '
      end
    end
    title
  end

  def activity_link_to(activity)
    case activity.state
    when Activity::STATE_DEVELOPMENT
      link_to activity, app_activity_path(activity.app, activity)
    when Activity::STATE_VERSIONED
      link_to activity, app_activity_versions_path(activity.app, activity)
    when Activity::STATE_DEPLOYED
      link_to activity, app_activity_versions_path(activity.app, activity)
    else
      logger.warn "Tried to link to a activity with unknown state (#{activity.to_s})"
      link_to activity, app_activities_path(activity.app)
    end
  end

  def brazil_release
    "#{AppConfig.release_version} (#{AppConfig.release_name})"
  end

  def atom_feed_tag
    case "#{controller.controller_name}-#{controller.action_name}"
    when 'apps-index'
      auto_discovery_link_tag :atom, apps_path(:id => params[:id], :format => 'atom'), {:title => "Apps"}
    when 'activities-index'
      auto_discovery_link_tag :atom, app_activities_path(:app_id => params[:app_id], :format => 'atom'), {:title => "Activities"}
    when 'activities-show'
      auto_discovery_link_tag :atom, app_activity_path(:app_id => params[:app_id], :id => params[:id], :format => 'atom'), {:title => "Activity Changes"}
    when 'versions-index'
      auto_discovery_link_tag :atom, app_activity_versions_path(:id => params[:id], :format => 'atom'), {:title => "Activity Versions"}
    end
  end

  def truncate_words(text, length = 30, end_string = '...')
    words = text.split
    words[0...length].join(' ') + (words.length > length ? end_string : '')
  end

  def email_to_realname(email)
    email.split('@').first.split('.').each {|email_part| email_part.capitalize!}.join(' ') unless email.nil?
  end
  
  
  def delete_warning_text deletable_entity
    warning = "YOU ARE ABOUT TO DELETE A#{"N" if deletable_entity.class.to_s[0] == 65 } #{deletable_entity.class.to_s.upcase}!\n\n"
    warning << "Are you really sure you want to delete the #{deletable_entity.class.to_s.downcase}:\n- #{deletable_entity}\n\n"
    
    case deletable_entity.class.to_s
      when App.to_s
        warning << "Deleting this app will also delete the following actvivites:\n"
        deletable_entity.activities.each do |activity|
          warning << "- #{activity}, #{activity.changes.count} changes, #{activity.state}\n"
        end
        warning << "\n"
      when Activity.to_s
        warning << "Deleting this activity will delete all of its changes and any versions.\n"
        warning << "\n"
      when Change.to_s
        cut_off_length = 400
        last_2_lines = ''
        last_2_lines = deletable_entity.sql.split("\n").pop if deletable_entity.sql.length > cut_off_length
        warning << "SQL:\n#{truncate(deletable_entity.sql, :length => cut_off_length, :seperator => "\n", :omission => "\n\n... (continued, #{deletable_entity.sql.length-cut_off_length-last_2_lines.length} chars) ...\n")}\n"
        warning << last_2_lines 
        warning << "\n"
    end
    warning
  end
end
