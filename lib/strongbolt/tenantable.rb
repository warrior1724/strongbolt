module StrongBolt
  module Tenantable
    module ClassMethods
      #
      # Specifies that the class can be tenanted
      # It will traverse all the has_many relationships
      # and add a has_one :tenant if not specified
      #
      @@tenant = false
      def tenant
        @@tenant = true
      end

      def tenant?() @@tenant; end

    end
    
    module InstanceMethods
      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end