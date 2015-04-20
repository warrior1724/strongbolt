module Strongbolt
  module UserAbilities
    module ClassMethods
      
    end
    
    module InstanceMethods
      #----------------------------------------------------------#
      #                                                          #
      #  Returns all the user's capabilities plus inherited ones #
      #                                                          #
      #----------------------------------------------------------#
      def capabilities
        @capabilities_cache ||= Strongbolt::Capability.unscoped.joins(:roles)
          .joins('INNER JOIN strongbolt_roles as children_roles ON strongbolt_roles.lft <= children_roles.lft AND children_roles.rgt <= strongbolt_roles.rgt')
          .joins('INNER JOIN strongbolt_roles_user_groups rug ON rug.role_id = children_roles.id')
          .joins('INNER JOIN strongbolt_user_groups_users ugu ON ugu.user_group_id = rug.user_group_id')
          .where('ugu.user_id = ?', self.id).distinct
      end

      #
      # Adds a managed tenant to the user
      #
      def add_tenant tenant
        sing_tenant_name = tenant.class.name.demodulize.underscore
        send("users_#{sing_tenant_name.pluralize}").create! sing_tenant_name => tenant
        # users_tenants.create! tenant: tenant
      end

      #
      # Main method for user, used to check whether the user
      # is authorized to perform a certain action on an instance/class
      #
      def can? action, instance, attrs = :any, all_instance = false
        without_grant do
      
          # Get the actual instance if we were given AR
          instance = instance.try(:first) if instance.is_a?(ActiveRecord::Relation)
          return false if instance.nil?
          
          # We require this to be an *existing* user, that the action and attribute be symbols
          # and that the instance is a class or a String
          raise ArgumentError, "Action must be a symbol and instance must be Class, String, Symbol or AR" unless self.id.present? && action.is_a?(Symbol) && 
             (instance.is_a?(ActiveRecord::Base) || instance.is_a?(Class) || instance.is_a?(String)) && attrs.is_a?(Symbol)
        
          # Pre-populate all the capabilities into a results cache for quick lookup. Permissions for all "non-owned" objects are
          # immediately available; additional lookups are required for owned objects (e.g. User, MediaMarket, etc.).
          # The results cache key is formatted as "action model attribute" (attribute can be any, all or an actual attribute)
          # -any, all, an ID, or "owned" (if the ID will be verified later) is appended to the key based on which instances
          # a user has access to
          populate_capabilities_cache unless @results_cache.present?
           
          # Determine the model name and the actual model (if we need to traverse the hierarchy)
          if instance.is_a?(ActiveRecord::Base)
            model = instance.class
            model_name = model.name_for_authorization
          elsif instance.is_a?(Class)
            model = instance
            model_name = model.name_for_authorization
          else
            model = nil # We could do model_name.constantize, but there's a big cost to doing this
                        # if we don't need it, so just defer until we determine there's an actual need
            model_name = instance
          end
          
          # Look up the various possible valid entries in the cache that would allow us to see this
          return capability_in_cache?(action, instance, model_name, attrs, all_instance)

        end #end w/o grant   
      end

      #
      # Convenient method
      #
      def cannot? *args
        !can? *args
      end

      #
      # Checks if the user owns the instance given
      #
      def owns? instance
        raise ArgumentError unless instance.is_a?(Object) && !instance.is_a?(Class)
        # If the user id is set, does this (a) user id match the user_id field of the instance
        # or (b) if this is a User instance, does the user id match the instance id?
        key = instance.is_a?(User) ? :id : :user_id
        return !id.nil? && instance.try(key) == id
      end



      #
      # Populate the capabilities cache
      #
      def populate_capabilities_cache
        beginning = Time.now
        
        @results_cache ||= {}
        @model_ancestor_cache ||= {}

        # User can find itself by default
        @results_cache["findUserany-any"] = true
        @results_cache["findUserany-#{id}"] = true
        
        #
        # Store every capability fetched
        #
        capabilities.each do |capability|

          k = "#{capability.action}#{capability.model}"
          attr_k = capability.attr || 'all'
          
          @results_cache["#{k}#{attr_k}-any"] = true
          @results_cache["#{k}any-any"] = true

          if capability.require_ownership
            user_id = self.try(:id)
            # We can use the ID of the User object for the key here because
            # there's only one of them
            if capability.model == 'User'
              @results_cache["#{k}#{attr_k}-#{user_id}"] = true
              @results_cache["#{k}any-#{user_id}"] = true
            else
            # On the other hand, it doesn't make sense to pre-populate the valid
            # IDs for the thousands of MMs, CDs, and States when we probably are never
            # going to need to know this. Instead, adding 'owned' is a hint to actually look
            # up later if we own a particular geography.
              @results_cache["#{k}#{attr_k}-owned"] = true
              @results_cache["#{k}any-owned"] = true
            end
          elsif capability.require_tenant_access # If tenant access required
            @results_cache["#{k}#{attr_k}-tenanted"] = true
            @results_cache["#{k}any-tenanted"] = true
          else
            @results_cache["#{k}#{attr_k}-all"] = true
            @results_cache["#{k}any-all"] = true
          end
        end # End each capability

        Strongbolt.logger.info "Populated capabilities in #{(Time.now - beginning)*1000}ms"
      
        @results_cache
      end # End Populate capabilities Cache





      #----------------------------------------------------------#
      #                                                          #
      #  Checks if the user can perform 'action' on 'instance'   #
      #                                                          #
      #----------------------------------------------------------#
      
      def capability_in_cache?(action, instance, model_name, attrs = :any, all_instance = false)
        action_model = "#{action}#{model_name}"
        
        Strongbolt.logger.warn "User has no results cache" if @results_cache.empty?
        Strongbolt.logger.debug { "Authorizing user to perform #{action} on #{instance.inspect}" }

        # we don't know or care about tenants or if this is a new record
        if instance.is_a?(ActiveRecord::Base) && !instance.new_record?
          
          # First, check if we have a hash/cache hit for User being able to do this action to every instance of the model/class
          return true if @results_cache["#{action_model}all-all"]  #Access to all attributes on ENTIRE class?
          return true if @results_cache["#{action_model}#{attrs}-all"]  #Access to this specific attribute on ENTIRE class?
          
          # If we're checking on a specific instance of the class, not the general model,
          # append the id to the key
          id = instance.try(:id)
          return true if @results_cache["#{action_model}all-#{id}"] # Access to all this instance's attributes?
          return true if @results_cache["#{action_model}#{attrs}-#{id}"] #Access to this instance's attribute?
          
          # Checking ownership and tenant access
          # Block access for non tenanted instance
          valid_tenants = has_access_to_tenants?(instance)

          # Then if the model is owned but isn't preloaded yet
          if instance.class.owned?
            # Tests if the owner id of the instance is the same than the user
            if (own_instance = instance.strongbolt_owner_id == self.id)
              @results_cache["#{action_model}all-#{id}"] = own_instance && valid_tenants && @results_cache["#{action_model}all-owned"]
              @results_cache["#{action_model}#{attrs}-#{id}"] = own_instance && valid_tenants && @results_cache["#{action_model}#{attrs}-owned"]
              return true if @results_cache["#{action_model}all-#{id}"] || @results_cache["#{action_model}#{attrs}-#{id}"]
            else
              @results_cache["#{action_model}all-#{id}"] = false
              @results_cache["#{action_model}#{attrs}-#{id}"] = false
            end
          end

          # Finally we check for tenanted instances
          @results_cache["#{action_model}all-#{id}"] = @results_cache["#{action_model}all-tenanted"] && valid_tenants  #Access to all attributes on tenanted class?
          @results_cache["#{action_model}#{attrs}-#{id}"] =  @results_cache["#{action_model}#{attrs}-tenanted"] && valid_tenants #Access to this specific attribute on tenanted class?
          return true if @results_cache["#{action_model}all-#{id}"] || @results_cache["#{action_model}#{attrs}-#{id}"]
        elsif instance.is_a?(ActiveRecord::Base) && instance.new_record?
          return true if @results_cache["#{action_model}all-all"]  #Access to all attributes on ENTIRE class?
          return true if @results_cache["#{action_model}#{attrs}-all"]  #Access to this specific attribute on ENTIRE class?
          # Checking if the instance is from valid tenants (if necessary)
          valid_tenants = has_access_to_tenants?(instance)
          return true if @results_cache["#{action_model}all-tenanted"] && valid_tenants  #Access to all attributes on tenanted class?
          return true if @results_cache["#{action_model}#{attrs}-tenanted"] && valid_tenants #Access to this specific attribute on tenanted class?

          # Finally, in the case where it's a non tenanted model (it still need to have valid_tenants == true)
          return true if @results_cache["#{action_model}all-any"] && valid_tenants
          return true if @results_cache["#{action_model}#{attrs}-any"] && valid_tenants
        else
          # First, check if we have a hash/cache hit for User being able to do this action to every instance of the model/class
          return true if @results_cache["#{action_model}all-all"]  #Access to all attributes on ENTIRE class?
          return true if @results_cache["#{action_model}#{attrs}-all"]  #Access to this specific attribute on ENTIRE class?
          return true if @results_cache["#{action_model}all-any"] && ! all_instance  #Access to all attributes on at least once instance?
          return true if @results_cache["#{action_model}#{attrs}-any"] && ! all_instance  #Access to this specific attribute on at least once instance?
        end
        #logger.info "Cache miss for checking access to #{key}"
        
        return false
      end

      #
      # Checks if the instance given fulfills tenant management rules
      #
      def has_access_to_tenants? instance, tenants = nil        
        # If no tenants list given, we take all
        tenants ||= Strongbolt.tenants
        # Populate the cache if needed
        populate_tenants_cache

        # Go over each tenants and check if we access to at least one of the tenant
        # models linked to it
        tenants.inject(true) do |result, tenant|
          begin
            if instance.class == tenant
              tenant_ids = [instance.id]
            elsif instance.respond_to?(tenant.singular_association_name)
              if instance.send(tenant.singular_association_name).present?
                tenant_ids = [instance.send(tenant.singular_association_name).id]
              else
                tenant_ids = []
              end
            elsif instance.respond_to?(tenant.plural_association_name)
              tenant_ids = instance.send("#{tenant.singular_association_name}_ids")
            else
              next result
            end
          # When we perform a :select on a model, we may omit
          # the attribute(s) that link(s) to the tenant.
          # In that case, we have to suppose the user has access
          rescue ActiveModel::MissingAttributeError
            tenant_ids = []
          end
          result && (tenant_ids.size == 0 || (@tenants_cache[tenant.name] & tenant_ids).present?)
        end
      end

      #
      # Populate a hash of tenants as keys and ids array as values
      #
      def populate_tenants_cache
        return if @tenants_cache.present?

        Strongbolt.logger.debug "Populating tenants cache for user #{self.id}"
        
        @tenants_cache = {}
        # Go over each tenants
        Strongbolt.tenants.each do |tenant|
          @tenants_cache[tenant.name] = send("#{tenant.singular_association_name}_ids").to_a
          Strongbolt.logger.debug "#{@tenants_cache[tenant.name].size} #{tenant.name}"
        end
      end


    end # End InstanceMethods
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods

      receiver.class_eval do
        has_and_belongs_to_many :user_groups,
          :foreign_key => :user_id,
          :class_name => "Strongbolt::UserGroup",
          :join_table => :strongbolt_user_groups_users
          # :inverse_of => :users doesn't seem available before AR 4.1.5
        has_many :roles, through: :user_groups

        has_many :users_tenants, class_name: "Strongbolt::UsersTenant",
          foreign_key: :user_id, :inverse_of => :user,
          :dependent => :delete_all
      end

      # Sets up user association
      Strongbolt.tenants.each do |tenant|
        tenant.send :setup_association_on_user
      end
    end
  end
end