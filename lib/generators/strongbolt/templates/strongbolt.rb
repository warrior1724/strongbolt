Strongbolt.setup do |config|
  # Configure here the logger used by Strongbolt
  config.logger = Rails.logger

  #
  # Set here the class name of your user class, if different than "User"
  #
  # config.user_class = "User"

  #
  # You can use this block to perform specific actions when a user is denied the access somewhere
  #
  # config.access_denied do |user, instance, action, request|
  #   Rails.logger.warn "User #{user.try :id} was refused to perform #{action} on #{instance.try :inspect} with request #{request}"
  # end

  #
  # Specify here the list of tenants used by your application
  #
  # config.tenants = "Client", "Region"

  #
  # You can specify here some controllers where you don't want to perform any controller authorization check up
  # It can be useful for instance with devise controllers, to avoid subclassing them.
  # Write the controller names the same way you would with routes
  #
  # config.skip_controller_authorization_for "devise/confirmation"

  #
  # List here the set of default permissions granted to every user
  # You will usually let every user access its own information for instance
  #
  config.default_capabilities = [
    {:model => "User", :require_ownership => true, :require_tenant_access => false, :actions => [:find]}
  ]

  #
  # If given a tenant, Strongbolt will try to detect all the models within your application.
  # However, if some models don't have any direct or indirect dependencies on one of your tenant,
  # Strongbolt won't find it.
  #
  # You can list here all the models of your application that doesn't indirectly belong to a tenant.
  #
  config.models = %MODELS%
end
