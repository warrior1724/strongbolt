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

      #
      # Not secure if Grant is disabled, there's no current user
      # or if we're using Rails console 
      #
      def unbolted?
        Grant::Status.grant_disabled? || (defined?(Rails) && defined?(Rails.console)) ||
           Grant::User.current_user.nil?
      end

      #
      # Returns true if the model is owned, ie if it has a belongs_to
      # relationship with the user class
      #
      def owned?
        @owned ||= name == Configuration.user_class || owner_association.present?
      end

      #
      # Returns the association to the user, if present
      #
      def owner_association
        @owner_association ||= reflect_on_all_associations(:belongs_to).select do |assoc|
          assoc.klass.name == Configuration.user_class
        end.try(:first)
      end

      #
      # Returns the name of the attribute containing the owner id
      #
      def owner_attribute
        return unless owned?

        @owner_attribute ||= if name == Configuration.user_class
          :id
        else
          owner_association.foreign_key.to_sym
        end
      end

    end
    
    module InstanceMethods
      #
      # Asks permission to performa an operation on the current instance
      #
      def accessible?(action, attrs = :any)
        unbolted? || Grant::User.current_user.can?(action, self, attrs)
      end

      #
      # Returns the owner id according to what's
      #
      def owner_id
        raise ModelNotOwned unless self.class.owned?

        send self.class.owner_attribute
      end
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods

      #
      # We use the grant helper method to test authorizations on all methods
      #
      receiver.grant(:find, :create, :update, :destroy) do |user, instance, action|
        # Check the user permission unless unbolted
        granted = unbolted? ? true : user.can?( action, instance )

        # If not granted, trigger the access denied
        unless granted
          StrongBolt.access_denied user, instance, action, $request.try(:fullpath)
        end
        
        granted
      end # End Grant
    end
  end
end