Strongbolt.setup do |config|
  # Configure here the logger used by Strongbolt
  config.logger = Rails.logger

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
end