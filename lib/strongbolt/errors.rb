module StrongBolt
  StrongBoltError = Class.new StandardError

  #
  # Copy & Paste of Grant Error
  #
  class Unauthorized < StrongBoltError
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
        user_str = user == nil ? 'Anonymous' : "#{user.try(:class).try(:name)}:#{user.try :id}"
        model_str = model.is_a?(Class) ? "#{model.try :name}" : "#{model.try(:class).try(:name)}"
        "#{action} permission not granted to #{user_str} for resource #{model_str}:#{model.try :id}"
      end
    end
  end
  
  ModelNotFound = Class.new StrongBoltError
  ActionNotConfigured = Class.new StrongBoltError

  WrongUserClass = Class.new StrongBoltError
  ModelNotOwned = Class.new StrongBoltError

  TenantError = Class.new StrongBoltError
  InverseAssociationNotConfigured = Class.new TenantError
  DirectAssociationNotConfigured = Class.new TenantError
end