// GUINET Module
GUINET = (function() {

  var init = function() {
    switch(window.location.search) {
      case '?route=index': GUINET.index.init(); break;
      case '?route=home': GUINET.home.init(); break;
      case '?route=signup': GUINET.signup.init(); break;
      case '?route=signin': GUINET.signin.init(); break;
      case '?route=settings': GUINET.settings.init(); break;
    }
  };

  return {
    init: init
  };

})();


// Settings Submodule
GUINET.index = (function() {

  var init = function() {
  };

  return {
    init: init
  };

})();


// Home Submodule
GUINET.home = (function() {


  // Widget Factory
  function WidgetFactory() {
  }

  WidgetFactory.prototype.create = function(type, parameters) {
    switch(type) {
      case 'bookmark':
        return new Bookmark(parameters.widgetManager, parameters.html);
        break;
      case 'note':
        return new Note(parameters.widgetManager, parameters.html);
        break;
      case 'browser':
        //return Browser(parameters.widgetManager, parameters.html);
        break;
      case 'texteditor':
        //return TextEditor(parameters.widgetManager, parameters.html);
        break;
      case 'imageviewer':
        //return ImageViewer(parameters.widgetManager, parameters.html);
        break;
      case 'chat':
        //return Chat(parameters.widgetManager, parameters.html);
        break;
    }
  }


  // Widget Manager
  function WidgetManager(ajax, widgetFactory) {
    this.ajax = ajax;
    this.widgetFactory = widgetFactory;
    this.widgets = [];
  }

  WidgetManager.prototype.add = function(widget) {
    return this.widgets.push(widget);
  }

  WidgetManager.prototype.remove = function(widget) {
    this.widgets.splice(this.widgets.indexOf(widget), 1);
  }

  WidgetManager.prototype.get = function(index) {
    if(index > -1 && index < this.widgets.length) {
      return this.widgets[index];
    }
  }

  WidgetManager.prototype.set = function(index, widget) {
    if(index > -1 && index < this.widgets.length) {
      this.widgets[index] = widget;
    }
  }

  WidgetManager.prototype.save = function() {
    var data = [];
    for(var i=0; i<this.widgets.length; i++)
      data = data.concat(this.widgets[i].json());
    this.ajax.set(data, null);
  }

  WidgetManager.prototype.load = function() {
    this.ajax.get(null, function(data) {
      $('.message').fadeOut('slow', function() {
        $(this).remove();
      });

      // If user has no widgets, initialize a Note
      if(data.length <= 0) {
        this.widgetFactory.create('note', {widgetManager: this, html: undefined});
      }

      // If user has widgets, initialize them all
      for (var i=0; i<data.length; i++) {
        var type = data[i].type;
        var parameters = {widgetManager: this, html: data[i].html};
        var widget = this.widgetFactory.create(type, parameters);
      }
    }.bind(this));
  }


  // Widget
  function Widget(widgetManager) {
    if (widgetManager == undefined) return;
    this.widgetManager = widgetManager;
    this.widgetManager.add(this);
  }


  // Bookmark Widget
  Bookmark.prototype = new Widget();
  Bookmark.prototype.constructor = Bookmark;
  Bookmark.prototype.parent = Widget.prototype;

  function Bookmark(widgetManager, html) {
    this.parent.constructor.call(this, widgetManager);

    this.html = '<article class="widget bookmark"><div class="window"><header class="titlebar clearfix"><h1 class="label"></h1><button type="button" value="delete" class="button">-</button></header><div class="toolbar clearfix"><input type="text" placeholder="New Item" class="textbox"/><button type="button" value="add" class="button">+</button></div><ul class="listbox"><li class="item clearfix"><a href="#" target="_blank" class="link"></a><button type="button" value="delete" class="button">-</button></li></ul></div></article>';

    this.$object = $((html == undefined) ? this.html : html);

    this.setup();
    this.render((html == undefined) ? (this.widgetManager.save).bind(this.widgetManager) : undefined);
  }

  Bookmark.prototype.setup = function() {
    // Make widget draggable
    this.$object
      .draggable({
        cursor: 'move',
        handle: '.titlebar',
        containment: '#content',
        stack: '.widget',
        snap: true,
        stop: function(event, ui) {
          this.widgetManager.save();
        }.bind(this)
      });

    // Make widget deletable
    this.$object.find('.titlebar>.button[value="delete"]')
      .click(function(event) {
        this.$object.fadeOut('slow', function() {
          this.$object.remove();
          this.widgetManager.remove(this);
          this.widgetManager.save();
        }.bind(this));
      }.bind(this));

    // Make widget titlebar label editable
    this.$object.find('.titlebar>.label')
      .editable(function(value, settings) {
        return value;
      }, {
        event: 'contextmenu',
        cssclass: 'editable',
        placeholder: 'Right-click to edit',
        onblur: 'submit',
        callback: function(value, settings) {
          this.widgetManager.save();
        }.bind(this)
      });

    // Make widget listbox sortable
    this.$object.find('.listbox')
      .sortable({
        forcePlaceholderSize : true,
        update: function(event, ui) {
          this.widgetManager.save();
        }.bind(this)
      });

    // Setup widget toolbar
    this.$object.find('.toolbar>.button[value="add"]')
      .click(function(event) {
        var $input = this.$object.find('.toolbar>.textbox');

        // Test for invalid input value
        if(($input.val().length > 0) && (/^[a-z]+:\/\//i.test($input.val()))) {
          $item = $(this.html).find('.item').clone();

          // Initialise and make new item editable
          $item.children('.link')
            .attr('href', $input.val())
            //FIXME: .text(new URL($input.val()).hostname.replace(/www\d*\./i, '').split('.')[0])
            .text($input.val().replace(/www\d*\./i, '').split('.')[0])
            .editable(function(value, settings) {
              return value;
            }, {
              event: 'contextmenu',
              cssclass: 'editable',
              placeholder: 'Right-click to edit',
              onblur: 'submit',
              callback: function(value, settings) {
                this.widgetManager.save();
              }.bind(this)
            });

          // Make new item clickable
          $item.children('.link')
            .click(function(event) {
              if ($('iframe').is(':visible')) {
                event.preventDefault();
                $('iframe').attr('src', $(this).attr('href'));
              }
            });

          // Make new item deletable
          $item.children('.button')
            .click(function(event) {
              $item.fadeOut('slow', function() {
                $item.remove();
                this.widgetManager.save();
              }.bind(this))
            }.bind(this));

          // Append new item to listbox
          $item.prependTo(this.$object.find('.listbox')).hide().fadeIn('slow', function() {
            this.widgetManager.save();
          }.bind(this));

          $input.attr('placeholder', 'New Item');
        } else {
          $input.attr('placeholder', 'Invalid URL');
        }

        $input.val('');
      }.bind(this));


    // Setup widget existing listbox items
    this.$object.find('.item')
      .each(function(index, value) {
        var $item = $(value);

        // Make item editable
        $item.children('.link')
          .editable(function(value, settings) {
            return value;
          }.bind(this), {
            event: 'contextmenu',
            cssclass: 'editable',
            placeholder: 'Right-click to edit',
            onblur: 'submit',
            callback: function(value, settings) {
              this.widgetManager.save();
            }.bind(this)
          });

          // Make new item clickable
          $item.children('.link')
            .click(function(e) {
              if ($('iframe').is(':visible')) {
                e.preventDefault();
                $('iframe').attr('src', $(this).attr('href'));
              }
            });

        // Make item deletable
        $item.children('.button')
          .click(function(event) {
            $item.fadeOut('slow', function() {
              $item.remove();
              this.widgetManager.save();
            }.bind(this))
          }.bind(this));
      }.bind(this));
  }

  Bookmark.prototype.render = function(callback) {

    this.$object.css({'position': 'absolute'}); // FIXME
    this.$object.appendTo('#content').hide().fadeIn('slow', callback);

  };

  Bookmark.prototype.json = function() {
    var json = [
      {
        type: 'bookmark',
        html: this.$object.prop('outerHTML')
      }
    ];

    return json;
  };


  // Note Widget
  Note.prototype = new Widget();
  Note.prototype.constructor = Note;
  Note.prototype.parent = Widget.prototype;

  function Note(widgetManager, html) {
    this.parent.constructor.call(this, widgetManager);

    this.html = '<article class="widget note"><div class="window"><header class="titlebar clearfix"><h1 class="label">Notes</h1></header><div class="toolbar clearfix"><select class="dropdown"><option>Select Widget:</option><option value="bookmark">Bookmark</option><option value="texteditor">Text Editor</option><option value="chat">Chat</option><option value="imageviewer">Image Viewer</option><option value="browser">Browser</option></select></div><ul class="listbox"><li class="item"><h1 class="label">Add widget from the drop-down menu.</h1></li><li class="item"><h1 class="label">Delete widget from the delete button on the right of the titlebar.</h1></li><li class="item"><h1 class="label">Move widget from the titlebar.</h1></li><li class="item"><h1 class="label">Right-click widget titlebar to rename.</h1></li></ul></div></article>';

    this.$object = $((html == undefined) ? this.html : html);

    this.setup();
    this.render((html == undefined) ? this.widgetManager.save.bind(this) : undefined);
  }

  Note.prototype.setup = function() {
    // Make widget draggable
    this.$object
      .draggable({
        cursor: 'move',
        handle: '.titlebar',
        containment: '#content',
        stack: '.widget',
        stop: function() {
          this.widgetManager.save();
        }.bind(this)
      });

    // Setup widget dropdown
    this.$object.find('.toolbar>.dropdown')
      .change(function(event) {
        var type = $(event.target).val();
        var parameters = {widgetManager: this.widgetManager, html: undefined};
        var widget = this.widgetManager.widgetFactory.create(type, parameters);

        $(event.target).find('option').prop('selected', false);
      }.bind(this));
  }

  Note.prototype.render = function(callback) {
    this.$object.css({'position':'absolute'}); // FIXME
    this.$object.appendTo('#content').hide().fadeIn('slow', callback);
  }

  Note.prototype.json = function() {
    var json = [
      {
        type: 'note',
        html: this.$object.prop('outerHTML')
      }
    ];

    return json;
  };


  // Control
  function Control(widgetManager) {
    this.widgetManager = widgetManager;

    $(window).keypress(function(event) {
      this.run(event.which);
    }.bind(this));
  }

  Control.prototype.run = function(key) {
    switch(key) {
      case 102:
        this.fullscreen();
        break;
      case 98:
        this.iframe();
        break;
    }
  };

  Control.prototype.fullscreen = function() {
    $('body').children().not('iframe').fadeToggle('slow');
  };

  Control.prototype.iframe = function() {
    $('iframe').fadeToggle('slow');
  };


  // AJAX
  function AJAX() {
    this.url = 'http://localhost/guinet/index.php';
  }

  AJAX.prototype.get = function(data, callback) {
    $.ajax({
      type: 'GET',
      url: this.url + '?route=data&action=get',
      data: data,
      contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
      processData: false,
      dataType: 'json',
      success: callback
    });
  }

  AJAX.prototype.set = function(data, callback) {
    $.ajax({
      type: 'POST',
      url: this.url + '?route=data&action=set',
      data: JSON.stringify(data),
      contentType: 'application/json; charset=UTF-8',
      processData: false,
      dataType: 'json',
      success: callback
    });
  }


  // Home Submodule Initialization
  var init = function() {
    var widgetManager = new WidgetManager(new AJAX(), new WidgetFactory());
    widgetManager.load();

    var control = new Control(widgetManager);
  };

  return {
    init: init
  };

})();


// Signup Submodule
GUINET.signup = (function() {

  // Signup Submodule Initialization
  var init = function() {
  };

  return {
    init: init
  };
})();


// Signin Submodule
GUINET.signin = (function() {

  // Signin Submodule Initialization
  var init = function() {
  };

  return {
    init: init
  };
})();


// Settings Submodule
GUINET.Settings = (function() {

  // Settings Submodule Initialization
  var init = function() {
  };

  return {
    init: init
  };
})();


// Initialize document
$(document).ready(GUINET.init);
