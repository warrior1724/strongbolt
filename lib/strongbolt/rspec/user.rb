require 'rspec/mocks'
#
# We define a can! that allows to quickly stub a user authorization
#
Strongbolt.user_class_constant.class_eval do
  #
  # Best to use a class context and use class instance variables
  #
  class << self

    def authorizations
      @authorizations ||= {}
    end

    def set_authorization_for user, authorized, *args
      return if user.new_record?

      self.authorizations[user.id] ||= {}
      self.authorizations[user.id][key_for(*args)] = authorized
    end

    def clear_authorizations
      @authorizations = {}
    end

    def authorized? user, *args
      # Cannot do if user not saved
      return false if user.new_record?
      key = key_for(*args)
      if self.authorizations[user.id].present? && self.authorizations[user.id][key].present?
        return self.authorizations[user.id][key]
      else
        user._can? *args
      end
    end

    def key_for *args
      action = args[0]
      instance = args[1]
      attrs = args[2] || :any
      all_instances = (args[3] || false) ? "all" : "tenanted"
      if instance.is_a?(ActiveRecord::Base)
        model = instance.class.name
        if instance.new_record?
          "#{action}-#{model}-#{attrs}-#{all_instances}"
        else
          "#{action}-#{model}-#{attrs}-#{instance.id}"
        end
      else
        model = instance.class.name
        "#{action}-#{model}-#{attrs}-#{all_instances}"
      end
    end

  end

  #
  # 2 methods to setup mocking and stubs
  #
  def init
    RSpec::Mocks::setup(self) unless self.respond_to? :allow
  end

  def setup_stub authorized, arguments
    init
    # Set the authorizations on a class level
    self.class.set_authorization_for self, authorized, *arguments
  end

  #
  # Mocked methods
  #
  alias_method :_can?, :can?

  def can? *args
    self.class.authorized? self, *args
  end

  def can! *args
    setup_stub true, args
  end

  def cannot! *args
    setup_stub false, args
  end
end