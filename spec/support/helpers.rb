module Helpers
  def without_grant(&block)
    Grant::Status.without_grant(&block)
  end

  def define(name, klass = ActiveRecord::Base, &blk)
    mod, name = module_by_name(name)
    begin
      mod.send :remove_const, name
    rescue NameError
    ensure
      mod.send :const_set, name, Class.new(klass)
      # This ensures the class gets its name before configuring it
      mod.const_get(name).class_eval(&blk) unless blk.nil?
      # Store the right reference in the class cache
      ActiveSupport::Dependencies.reference mod.const_get(name)
    end
  end

  def define_model(name, &blk)
    define name, ActiveRecord::Base, &blk
  end

  def define_controller(name, &blk)
    define name, ActionController::Base, &blk
  end

  def undefine_model(*names)
    undefine(*names)
  end

  def undefine(*names)
    names.each do |name|
      begin
        mod, name = module_by_name(name)
        mod.send :remove_const, name
      rescue NameError
      end
    end
  end

  private

  def module_by_name(name)
    base_module = Object
    splits = name.split('::')
    if splits.size > 1
      splits[0...(splits.size - 1)].each do |module_name|
        # Get the module if it exists, or create it
        begin
          mod = base_module.const_get(module_name)
        rescue NameError
          mod = Module.new
          base_module.send :const_set, module_name, mod
        end
        base_module = mod
      end
    end
    # Returns both module and demodulized name
    [base_module, splits.last]
  end
end
