module Helpers
  def without_grant &block
    Grant::Status.without_grant &block
  end

  def define_model name, &blk
    begin
      Object.send :remove_const, name
    rescue NameError
    ensure
      Object.send :const_set, name, Class.new(ActiveRecord::Base)
      # This ensures the class gets its name before configuring it
      Object.const_get(name).class_eval &blk unless blk.nil?
      # Store the right reference in the class cache
      ActiveSupport::Dependencies.reference Object.const_get(name)
    end
  end

  def undefine_model name
    begin
      Object.send :remove_const, name
    rescue NameError
    end
  end
end