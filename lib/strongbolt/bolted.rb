#
# Included in the base class of models (ActiveRecord::Base),
# this module is the entry point of all authorization.
#
# It implements helper methods that will be used by a lot of other models
#
module StrongBolt
  module Bolted
    module ClassMethods
      #
      # Returns true if grant is currently enable, the user is set and we're not in the console
      # ie when we need to perform a check
      #
      def bolted?
        !unbolted?
      end

      def unbolted?
        Grant::Status.grant_disabled? || Grant::User.current_user.nil?
      end
    end
    
    module InstanceMethods
      #
      # Asks permission to performa an operation on the current instance
      #
      def accessible?(action, attrs = :any)
        unbolted? || Grant::User.current_user.can?(action, self, attrs)
      end
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods

      # We add the grant to filter everything
      receiver.class_eval do

        grant(:find, :create, :update, :destroy) do |user, instance, action|
          # Check the user permission unless unbolted
          granted = unbolted? ? true : user.can?( action, instance )

          # If not granted, trigger the access denied
          if !granted
            StrongBolt.access_denied user, instance, action, $request.try(:fullpath)
          end
          
          granted
        end # End Grant

      end
    end
  end
end