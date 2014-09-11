module StrongBolt
  module BoltedController

    #
    # Maps controller actions to CRUD operations
    #
    ACTIONS_MAPPING = {
      :index    => :find,
      :show     => :find,
      :edit     => :update,
      :update   => :update,
      :new      => :create,
      :create   => :create
    }
    
    module ClassMethods
      
    end
    
    module InstanceMethods

      private

      #
      # Sets the current user using the :current_user method.
      # Without Grant, as with it it would check if the user
      # can find itself before having be assigned anything...
      #
      # Better than having to set an anymous method for granting
      # find to anyone!
      #
      def set_current_user
        # To be accessible in the model when not granted
        $request = request
        Grant::Status.without_grant do
          StrongBolt.current_user = send(:current_user) if respond_to?(:current_user)
        end
      end

      #
      # Unset the current user, by security (needed in some servers with only 1 thread)
      #
      def unset_current_user
        StrongBolt.current_user = nil
      end

      #
      # Checks authorization on the object, without fetching it
      # so it can say yes to :index but won't authorize loading everything
      # after, in the model by model authorization
      #
      def check_authorization
        # If no user, no need
        if StrongBolt.current_user.present?
          begin
            # Current model
            begin
              obj = self.controller_name.classify.constantize
            rescue NameError => e
              StrongBolt.logger.warn "No class found for controller #{self.controller.name}"
              return
            end 

            # Unless it is authorized for this action
            unless StrongBolt.current_user.can? crud_operation_of(action_name), obj
              StrongBolt.access_denied current_user, obj, crud_operation_of(action_name), request.try(:fullpath)
              raise StrongBolt::Unauthorized
            end
          rescue StrongBolt::Unauthorized => e
            raise e
          rescue Exception => e
            raise e
          end
        else
          StrongBolt.logger.warn "No authorization checking because no current user"
        end
      end

      #
      # Returns the CRUD operations based on the action name
      #
      def crud_operation_of action
        ACTIONS_MAPPING[action.to_sym]
      end
      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods

      receiver.class_eval do
        # Compulsory filters
        before_filter :set_current_user
        after_filter :unset_current_user

        # Quick check of high level authorization
        before_filter :check_authorization

        # Raise StrongBolt error instead
        rescue_from Grant::Error do |e|
          rescue_action_without_handler StrongBolt::Unauthorized.new
        end

      end # End receiver class eval
    end # End self.included

  end
end