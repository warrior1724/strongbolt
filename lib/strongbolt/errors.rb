module Strongbolt
  StrongboltError = Class.new StandardError

  #
  # Copy & Paste of Grant Error
  #
  class Unauthorized < StrongboltError
    attr_reader :user, :action, :model

    def initialize(*args)
      if args.size == 3
        @user, @action, @model = args
      else
        @message = args[0]
      end
    end

    def to_s
      if @message
        @message
      else
        user_str = user.nil? ? 'Anonymous' : "#{user.try(:class).try(:name)}:#{user.try :id}"
        model_str = model.is_a?(Class) ? (model.try :name).to_s : "#{model.try(:class).try(:name)}:#{model.try :id}"
        "#{action} permission not granted to #{user_str} for resource #{model_str}"
      end
    end
  end

  ModelNotFound = Class.new StrongboltError
  ActionNotConfigured = Class.new StrongboltError

  WrongUserClass = Class.new StrongboltError
  ModelNotOwned = Class.new StrongboltError

  TenantError = Class.new StrongboltError
  InverseAssociationNotConfigured = Class.new TenantError
  DirectAssociationNotConfigured = Class.new TenantError
end
