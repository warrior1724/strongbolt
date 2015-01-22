(function() {
  var RoleCapabilities;

  RoleCapabilities = (function() {
    function RoleCapabilities(table) {
      this.table = table;
      this.url = this.table.data('url');
      this.setup();
    }

    RoleCapabilities.prototype.toggleAction = function(button) {
      var granted, params, parent;
      granted = !button.data('granted');
      button.blur();
      button.data("granted", granted);
      parent = button.parent();
      params = {
        model: parent.data('model'),
        require_ownership: parent.data('require-ownership'),
        require_tenant_access: parent.data('require-tenant-access'),
        action: button.data('action')
      };
      return this[granted ? 'addAction' : 'destroyAction'](params, function() {
        if (granted) {
          button.addClass('btn-success');
          return button.removeClass('btn-danger');
        } else {
          button.addClass('btn-danger');
          return button.removeClass('btn-success');
        }
      });
    };

    RoleCapabilities.prototype.destroyAction = function(params, callback) {
      var options;
      options = {
        data: {
          capability: params
        },
        type: "DELETE",
        complete: callback
      };
      return this.request(options);
    };

    RoleCapabilities.prototype.addAction = function(params, callback) {
      var options;
      options = {
        data: {
          capability: params
        },
        type: "POST",
        complete: callback
      };
      return this.request(options);
    };

    RoleCapabilities.prototype.request = function(options) {
      options.url = this.url;
      options.dataType = 'json';
      return $.ajax(options);
    };

    RoleCapabilities.prototype.setup = function() {
      return this.table.on('click', 'button[data-action]', (function(_this) {
        return function(event) {
          return _this.toggleAction($(event.currentTarget));
        };
      })(this));
    };

    return RoleCapabilities;

  })();

  $(document).ready(function() {
    return new RoleCapabilities($("#role-capabilities"));
  });

}).call(this);