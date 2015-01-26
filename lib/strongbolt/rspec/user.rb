require 'rspec/mocks'
#
# We define a can! that allows to quickly stub a user authorization
#
Strongbolt.user_class_constant.class_eval do
  def init
    RSpec::Mocks::setup(self) unless self.respond_to? :allow
  end

  def self.authorizations
    @@authorizations ||= {}
  end

  def self.set_authorization_for user, authorized, *args
    return if user.new_record?

    self.authorizations[user.id] ||= {}
    self.authorizations[user.id][key_for(*args)] = authorized
  end

  def self.clear_authorizations
    @@authorizations = {}
  end

  def self.authorized? user, *args
    # Cannot do if user not saved
    return false if user.new_record?
    key = key_for(*args)
    if self.authorizations[user.id].present? && self.authorizations[user.id][key].present?
      return self.authorizations[user.id][key]
    else
      user._can? *args
    end
  end

  def self.key_for *args
    action = args[0]
    instance = args[1]
    if instance.is_a?(ActiveRecord::Base)
      model = instance.class.name
      if instance.new_record?
        "#{action}-#{model}"
      else
        "#{action}-#{model}-#{instance.id}"
      end
    else
      model = instance.class.name
      "#{action}-#{model}"
    end
  end

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

  def setup_stub authorized, arguments
    init
    # Set the authorizations on a class level
    self.class.set_authorization_for self, authorized, *arguments
  end
end