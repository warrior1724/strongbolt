class RoleCapabilities
  constructor: (@table) ->
    @url = @table.data('url')

    @setup()

  #
  # Send an AJAX request to change status of action
  # and change button style
  #
  toggleAction: (button) ->
    granted = ! button.data('granted')

    button.blur()
    button.data "granted", granted

    parent = button.parent()

    params =
      model: parent.data 'model'
      require_ownership: parent.data 'require-ownership'
      require_tenant_access: parent.data 'require-tenant-access'
      action: button.data 'action'

    @[if granted then 'addAction' else 'destroyAction'](params, ->
      if granted
        button.addClass 'btn-success'
        button.removeClass 'btn-danger'
      else
        button.addClass 'btn-danger'
        button.removeClass 'btn-success'
    )

  #
  # Destroy action
  #
  destroyAction: (params, callback) ->
    options =
      data: 
        capability: params
      type: "DELETE"
      complete: callback

    @request options

  #
  # Add Action
  #
  addAction: (params, callback) ->
    options =
      data: 
        capability: params
      type: "POST"
      complete: callback

    @request options

  #
  # Call the ajax request
  #
  request: (options) ->
    options.url = @url
    # This is way more important than I though.
    # If not specified, the controller will redirect to
    # role path and jquery ajax will delete the role!!!
    options.dataType = 'json'

    $.ajax(options)



  setup: ->
    @table.on 'click', 'button[data-action]', (event) =>
      @toggleAction $(event.currentTarget)

$(document).ready ->
  new RoleCapabilities $("#role-capabilities")