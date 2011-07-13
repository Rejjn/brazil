jQuery.ajaxSetup({dataType: 'html'})

// Brazil namespace
var brazil = function() {
  function form_insert_ajax_submit(options) {
    var defaults = { show_form: '', inserted_fieldset: '', response_container: '', success: function(){}, error: function(){}, done: function(){} };
    var settings = jQuery.extend(defaults, options);

    jQuery(settings.inserted_fieldset).find('form').ajaxForm({
      beforeSubmit: function(formData, jqForm, options) {
        jQuery('input[type="submit"]', jqForm).attr('disabled', 'disabled');
      },
      success: function(responseText, statusText) {
        jQuery(settings.inserted_fieldset).remove();

        jQuery(settings.response_container).hide();
        jQuery(settings.response_container).empty().append(responseText);

        settings.success();
        settings.done();

        jQuery(settings.show_form).show();
        jQuery(settings.response_container).show();
      },
      error: function(XMLHttpRequest, textStatus, errorThrown) {
        jQuery(settings.inserted_fieldset).replaceWith(XMLHttpRequest.responseText);

        settings.error();
        settings.done();

        form_insert_ajax_submit(options);
      }
    });

    jQuery(settings.inserted_fieldset).find('.form_close').show();
    jQuery(settings.inserted_fieldset).find('.form_close').live("click", function() {
      jQuery(settings.inserted_fieldset).remove();
      jQuery(settings.show_form).show();

      //settings.done();

      return false;
    });
  }

  function form_inline_ajax_submit(options) {
    var defaults = { inserted_fieldset: '', form_container: null, success: function(){}, error: function(){}, done: function(){} };
    var settings = jQuery.extend(defaults, options);

    settings.form_container.find('form').ajaxForm({
          beforeSubmit: function(formData, jqForm, options) {
            jQuery('input[type="submit"]', jqForm).attr('disabled', 'disabled');
          },
          success: function(responseText, statusText) {
            settings.form_container.replaceWith(responseText);

            settings.success();
            settings.done();
          },
          error: function(XMLHttpRequest, textStatus, errorThrown) {
            settings.form_container.empty().append(XMLHttpRequest.responseText);

            settings.error();
            settings.done();

            form_inline_ajax_submit(options);
          }
        });

        jQuery(settings.inserted_fieldset).find('.form_close').show();
        jQuery(settings.inserted_fieldset).find('.form_close').live("click", function() {
          jQuery.get(settings.form_container.children('form').attr('action'), function(response) {
            settings.form_container.replaceWith(response);

            settings.done();
          });
          return false;
        });
  }

  return {
    on_load: {
      general: function() {
        brazil.flash.fadeout('#notice', 3000);
        brazil.info.setup_close('#error');
        brazil.manipulate.syntax_highlight();
      },
    },
    current_id: {
      app: function(id) {
        if (typeof(id) != 'undefined') {
          this.app_id = id;
          return true;
        }
        
        if (typeof(this.app_id) == 'undefined') { 
          var url = window.location.href;
          var app_id = url.substring(url.indexOf('apps/')+5, url.indexOf('/', url.indexOf('apps/')+5));
          return app_id;
        } else {
          return this.app_id;      
        }
      },
      activity: function(id) {
        if (typeof(id) != 'undefined') {
          this.activity_id = id;
          return true;
        }
        
        if (typeof(this.app_id) == 'undefined') { 
          var url = window.location.href;
          var activity_id = url.substring(url.indexOf('activities/')+11, url.indexOf('/', url.indexOf('activities/')+11));
          return activity_id;
        } else {
          return this.activity_id;      
        }
      },
      version: function(id) {
        if (typeof(id) != 'undefined') {
          this.version_id = id;
          return true;
        }
        
        if (typeof(this.app_id) == 'undefined') { 
          var url = window.location.href;
          var version_id = url.substring(url.indexOf('versions/')+9, url.indexOf('/', url.indexOf('versions/')+9));
          return version_id;
        } else {
          return this.version_id;      
        }
      },
    },
    version: {
      setup_new_version: function(options) {
        var defaults = { version_types: '', current_version: '.current_version', new_version_major: '#new_version_major', new_version_minor: '#new_version_minor', new_version_patch: '#new_version_patch'};
        var settings = jQuery.extend(defaults, options);
        
        jQuery(settings.version_types).change(function() {
         var version = jQuery(settings.current_version).html().split('_');
         var selected_type = jQuery(settings.version_types).val();
         
         if (selected_type == 'major') {
           version[0] = parseInt(version[0])+1; 
         } else if (selected_type == 'minor') {
           version[1] = parseInt(version[1])+1;
         } else if (selected_type == 'patch') {
           version[2] = parseInt(version[2])+1;
         }
         
         jQuery(settings.new_version_major).val(version[0]);
         jQuery(settings.new_version_minor).val(version[1]);
         jQuery(settings.new_version_patch).val(version[2]);
        });
      },
    },
    repo_browser: {
      set_url: function(browser, input_element) {
        //jQuery(browser).load(function(){
          var repo_browser = jQuery(browser);
          var url = '/';
          var tmp_url = String(repo_browser.attr('contentWindow').location);

          if (tmp_url.indexOf('=') != -1) {
            url = tmp_url.substring(tmp_url.lastIndexOf('=') + 1);
          }
          
          jQuery(input_element).val(url);
        //});
      },
    },
    move : {
      scrollable: function(id) {
        jQuery(id).css("position", "relative");
        jQuery(id).scrollFollow({
          speed: 1000,
          offset: 20,
          relativeTo: 'top',
        });
      }
    },
    flash : {
      notice: function(element) {
        element = typeof(element) != 'undefined' ? element : '#notice';
        jQuery.get('/flash/notice', function(response) {
          if (response != "") {
            jQuery(element).hide().empty().append(response).fadeIn('slow', function(){
              setTimeout('jQuery("' + element + '").fadeOut()', 4000);
            });
          }
        });
      },
      error: function(element) {
        element = typeof(element) != 'undefined' ? element : '#error';
        jQuery.get('/flash/error', function(response) {
          if (response != "") {
            jQuery(element).hide().empty().append(response).fadeIn('slow', function(){
              //setTimeout('jQuery("' + element + '").fadeOut()', 3000);
            });
            brazil.info.setup_close(element);
          }
        });
      },
      fadeout: function(element, time) {
        setTimeout('jQuery("' + element + '").fadeOut()', time);
      },      
      discard: function() {
        jQuery.get('/flash/notice', function() {
        });
      }
    },
    info : {
      setup_toggle: function(options) {
        var defaults = { container: '', affected_element: '', show_caption: 'Show', hide_caption: 'Hide'};
        var settings = jQuery.extend(defaults, options);
        
        jQuery.each(jQuery(settings.container), function(index, value) {
          if (jQuery(value).find('.visibilty_controlls').length == 0) {
            jQuery(value).prepend('<div class="visibilty_controlls"></div>');
          }
          var controller_box = jQuery(value).find('.visibilty_controlls')
          var affected_element = jQuery(value).find(settings.affected_element)
          brazil.info.hide(controller_box, affected_element, settings);        
        });        
      },
      show: function(controller_box, affected_element, options) {
        affected_element.slideDown();
        controller_box.empty().append('<a href="#">' + options.hide_caption + '</a>');
        controller_box.find('a').click(function() {
          brazil.info.hide(controller_box, affected_element, options);
          return false;
        });   
      },
      hide: function(controller_box, affected_element, options) {
        affected_element.fadeOut();
        controller_box.empty().append('<a href="#">' + options.show_caption + '</a>');
        controller_box.find('a').click(function() {
          brazil.info.show(controller_box, affected_element, options);
          return false;
        });
      },
      setup_close: function(container, affected_element) {
        affected_element = typeof(affected_element) != 'undefined' ? affected_element : container;

        jQuery(container).prepend('<a href="#" class="close_button"><img src="/images/forms/x.gif" alt=""/></a>');
        jQuery(container).find('.close_button').click(function() {
          jQuery(affected_element).fadeOut();
          return false;
        });
      } 
    },
    manipulate: {
      syntax_highlight: function() {
        if (typeof SyntaxHighlighter != "undefined") {
          SyntaxHighlighter.config.clipboardSwf = '/javascripts/syntaxhighlighter/clipboard.swf';
          SyntaxHighlighter.defaults.gutter = false;
          SyntaxHighlighter.highlight();
        }
      },
      expand: function(options) {
        var defaults = { expand_button: '', collapse_button: '', expand_container: '' };
        var settings = jQuery.extend(defaults, options);

        jQuery(settings.expand_button).live("click", function() {
          jQuery.get(this.href, function(response) {
            jQuery(settings.expand_button).parents(settings.expand_container).replaceWith(response);
          });

          return false;
        });
      }
    },
    request : {
      execute: function(options) {
        var defaults = { button: '', method: '', response_container: '', success: function(){}, error: function(){}, done: function(){} };
        var settings = jQuery.extend(defaults, options);

        jQuery(settings.button).click(function(event) {
          event.preventDefault();
          button = jQuery(this);
          
          var form = jQuery(this).attr('form');
          button.addClass('loading');
          button.attr('disabled', 'disabled');
          
          jQuery.ajax({
            url: form.action,
            type: settings.method,
            success: function(responseText, statusText) {
              jQuery(settings.response_container).empty().append(responseText);
              settings.success();
              settings.done();
              button.removeClass('loading');
              button.removeAttr('disabled');
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
              settings.error();
              settings.done();
              button.removeClass('loading');
              button.removeAttr('disabled');
            },
          });
        });
      },      
    },
    form : {
      update: function(options) {
        var defaults = { trigger_element: '', trigger_event: '', target_element: '', url: '', success: function(){}, error: function(){}, done: function(){} };
        var settings = jQuery.extend(defaults, options);

        jQuery(settings.trigger_element).live(settings.trigger_event, function() {
          jQuery.ajax({
            url: settings.url,
            type: 'GET',
            data: "arg=" + jQuery(settings.trigger_element).val(),
            success: function(responseText, statusText) {
              jQuery(settings.target_element).empty().append(responseText);
              settings.success();
              settings.done();
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
              settings.error();
              settings.done();
            },
          });
        });
      },
      inline: function(options) {
        var defaults = { show_form: '', form_container: '', success: function(){}, error: function(){}, done: function(){} };
        var settings = jQuery.extend(defaults, options);

        jQuery(settings.show_form).live("click", function() {
          var show_form = this;
          jQuery.get(this.href, function(response) {
            var form_container = jQuery(show_form).parents(settings.form_container);
            form_container.empty().append(response).show('blind');

            form_inline_ajax_submit({
              form_container: form_container,
              inserted_fieldset: settings.inserted_fieldset,
              success: settings.success,
              error: settings.error,
              done: settings.done
            });
          });

          return false;
        });
      },
      insert: function(options) {
        var defaults = { show_form: '', form_container: '', inserted_fieldset: '', response_container: '', success: function(){}, error: function(){}, done: function(){} };
        var settings = jQuery.extend(defaults, options);

        jQuery(settings.show_form).click(function() {
          jQuery(this).hide();

          jQuery.get(this.href, function(response) {
            jQuery(response).prependTo(settings.form_container);
            jQuery(settings.inserted_fieldset).show("drop", { direction: 'left' });

            form_insert_ajax_submit({
              inserted_fieldset: settings.inserted_fieldset,
              response_container: settings.response_container,
              show_form: settings.show_form,
              success: settings.success,
              error: settings.error,
              done: settings.done
            });
          });

          return false;
        });
      },
      insert_only: function(options) {
        var defaults = { show_form: '', form_container: '', inserted_fieldset: '', done: function(){} };
        var settings = jQuery.extend(defaults, options);

        jQuery(settings.show_form).live("click", function() {
          jQuery(this).hide();

          jQuery.get(this.href, function(response) {
            jQuery(response).prependTo(settings.form_container);
            jQuery(settings.inserted_fieldset).show("drop", { direction: 'left' });

            jQuery(settings.inserted_fieldset).find('.form_close').show();
            jQuery(settings.inserted_fieldset).find('.form_close').live("click", function() {
              jQuery(settings.inserted_fieldset).remove();
              jQuery(settings.show_form).show();

              settings.done();

              return false;
            });
          });

          return false;
        });
      },
      existing: function(options) {
        var defaults = { form_container: '', response_container: '', success: function(){}, error: function(){}, done: function(){} };
        var settings = jQuery.extend(defaults, options);

        jQuery(settings.form_container).find('form').ajaxForm({
          beforeSubmit: function(formData, jqForm, options) {
            jQuery('input[type="submit"]', jqForm).attr('disabled', 'disabled');
            jQuery('input[type="submit"]', jqForm).addClass('loading');
          },
          success: function(responseText, statusText) {
            jQuery(settings.response_container).hide();
            jQuery(settings.response_container).empty().append(responseText);

            settings.success();

            jQuery(settings.form_container).find('#form_error').hide();
            jQuery(settings.form_container).find('.fieldWithErrors').removeClass('fieldWithErrors');
            jQuery(settings.form_container).find('input[type="submit"]').removeAttr('disabled');
            jQuery(settings.form_container).find('input[type="submit"]').removeClass('loading');

            jQuery(settings.response_container).show();
            settings.done();
          },
          error: function(XMLHttpRequest, textStatus, errorThrown) {
            jQuery(settings.form_container).replaceWith(XMLHttpRequest.responseText);

            //jQuery(settings.form_container).find('input[type="submit"]').removeAttr('disabled');
            //jQuery('input[type="submit"]', jqForm).removeClass('loading');

            settings.error();

            settings.done();

            brazil.form.existing(options);
          }
        });
      }
    }
  }
}();
