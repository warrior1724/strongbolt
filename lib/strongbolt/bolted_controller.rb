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
      #
      # Allows defining a specific model for this controller,
      # if it cannot be infer from the controller name
      #
      def model_for_authorization= model
        @model_for_authorization = case model
        when Class then model
        when String then constantize_model(model)
        when nil then nil
        else
          raise ArgumentError, "Model for authorization must be a Class or the name of the Class"
        end 
      end

      #
      # Returns the model used for authorization,
      # using controller name if not defined
      #
      def model_for_authorization
        if @model_for_authorization.present?
          @model_for_authorization
        else
          return constantize_model controller_name.classify
        end
      end

      #
      # Skips controller authorization check for this controller
      # No argument given will skip for all actions,
      # and can be passed only: [] or except: []
      #
      def skip_controller_authorization opts = {}
        skip_before_action :check_authorization, opts
      end

      #
      # Skip all authorization checking for the controller,
      # or a subset of actions
      #
      def skip_all_authorization opts = {}
        skip_controller_authorization opts
        around_action :disable_authorization, opts
      end

      #
      # Sets what CRUD operation match a specific sets of non RESTful actions
      #
      [:find, :update, :create, :destroy].each do |operation|
        define_method "authorize_as_#{operation}" do |*args|
          args.each do |action|
            actions_mapping[action] = operation
          end
        end
      end

      #
      # Returns the actions mapping of this controller
      #
      def actions_mapping
        # Defaults to a duplicate of the standard mapping
        @actions_mapping ||= ACTIONS_MAPPING.dup
      end

      private

      #
      # Try to constantize a class
      #
      def constantize_model name
        begin
          name.constantize
        rescue NameError
          raise StrongBolt::ModelNotFound, "Model for controller #{controller_name} wasn't found"
        end
      end

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
              obj = self.class.model_for_authorization
            rescue StrongBolt::ModelNotFound
              StrongBolt.logger.warn "No class found or defined for controller #{controller_name}"
              return
            end 

            # Unless it is authorized for this action
            unless StrongBolt.current_user.can? crud_operation_of(action_name), obj
              StrongBolt.access_denied current_user, obj, crud_operation_of(action_name), request.try(:fullpath)
              raise StrongBolt::Unauthorized
            end
          rescue StrongBolt::Unauthorized => e
            raise e
          rescue => e
            raise e
          end
        else
          StrongBolt.logger.warn "No authorization checking because no current user"
        end
      end

      #
      # Catch Grant::Error and send StrongBolt::Unauthorized instead
      #
      def catch_grant_error
        begin
          yield
        rescue Grant::Error => e
          raise StrongBolt::Unauthorized, e.to_s
        end
      end

      #
      # Returns the CRUD operations based on the action name
      #
      def crud_operation_of action
        operation = self.class.actions_mapping[action.to_sym]
        # If nothing find, we raise an error
        if operation.nil?
          raise StrongBolt::ActionNotConfigured, "Action #{action} on controller #{self.class.controller_name} not mapped to a CRUD operation"
        end
        # Else ok
        operation
      end

      #
      # CAREFUL: this skips authorization !
      #
      def disable_authorization
        Grant::Status.without_grant { yield }
        StrongBolt.logger.warn "Authorization were disabled!"
      end
      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods

      receiver.class_eval do
        # Compulsory filters
        before_action :set_current_user
        after_action :unset_current_user

        # Quick check of high level authorization
        before_action :check_authorization

        # Catch Grant::Error
        around_action :catch_grant_error

      end # End receiver class eval
    end # End self.included

  end
end