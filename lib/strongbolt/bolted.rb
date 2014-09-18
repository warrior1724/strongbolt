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
           StrongBolt.current_user.nil?
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
          unless assoc.options.has_key? :polymorphic
            assoc.klass.name == Configuration.user_class
          else
            false
          end
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

      #
      # Returns the model name for authorization
      #
      def name_for_authorization
        @name_for_authorization ||= self.name
      end

      #
      # Authorize as another model
      #
      def authorize_as model_name
        @name_for_authorization = model_name
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
      receiver.send :include, StrongBolt::Tenantable
      receiver.send :include, Grant::Grantable

      # We add the grant to filter everything
      receiver.class_eval do

        #
        # We use the grant helper method to test authorizations on all methods
        #
        grant(:find, :create, :update, :destroy) do |user, instance, action|
          # StrongBolt.logger.debug { "Checking for #{action} on #{instance}\n\n#{Kernel.caller.join("\n")}" }
          # Check the user permission unless no user or rails console
          # Not using unbolted? here
          granted = ((defined?(Rails) && defined?(Rails.console)) || user.nil?) ||
            user.can?( action, instance )

          # If not granted, trigger the access denied
          unless granted
            StrongBolt.access_denied user, instance, action, $request.try(:fullpath)
          end
          
          granted
        end # End Grant

      end
    end
  end
end