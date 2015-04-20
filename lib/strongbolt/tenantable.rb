module Strongbolt
  module Tenantable
    module ClassMethods

      def tenant?() (@tenant.present? && @tenant) || Strongbolt.tenants.include?(name); end

      #
      # Returns associations potential name
      #
      def singular_association_name
        @singular_association_name ||= self.name.demodulize.underscore.to_sym
      end
      def plural_association_name
        @plural_association_name ||= self.name.demodulize.underscore.pluralize.to_sym
      end

      private

      #
      # Specifies that the class can be tenanted
      # It will traverse all the has_many relationships
      # and add a has_one :tenant if not specified
      #
      def tenant opts = {}
        # Stops if already configured
        return if tenant?

        Strongbolt.logger.debug "-------------------------------------------------------------------\n" +
          "Configuring tenant #{self.name}\n" +
          "-------------------------------------------------------------------\n\n"
        #
        # We're traversing using BFS the relationships
        #
        # Keep track of traversed models and their relationship to the tenant
        @models_traversed = {self.name => self}
        # File of models/associations to traverse
        models_to_traverse = reflect_on_all_associations
        while models_to_traverse.size > 0
          # BFS search, shiftin first elt of array (older)
          current_association = models_to_traverse.shift
          # We don't check has_many :through association,
          # only first degree relationships. It makes sense as we'll
          # obviously also be checking the models concerned with the through
          # relationship, using the intermediate model before.

          # So unless we've already traversed this model, or that's a through relationship
          # or a polymorphic association
          # Also we don't go following belongs_to relationship, it becomes crazy
          if should_visit? current_association
            # We setup the model using the association given
            method = setup_model(current_association)
            # We flag the model, storing the name of the method used to link to tenant
            @models_traversed[current_association.klass.name] = method
            # And add its relationships into the array, at the end, if method not nil
            if method.present?
              models_to_traverse.concat current_association.klass.reflect_on_all_associations
            end
          end
        end

        # We add models name to Configuration
        Strongbolt::Configuration.models = @models_traversed.keys

        create_users_tenant_subclass
        setup_association_on_user

        @tenant = true
      end

      #
      # Setup a model and returns the method name in symbol of the
      # implemented link to the tenant
      #
      def setup_model association
        # Source class
        original_class = association.active_record
        # Current class
        klass = association.klass
        # Get the link of original class to tenant
        link = @models_traversed[original_class.name]

        # If the original class is the actual tenant, it should have defined
        # the reverse association as we cannot guess it
        if original_class == self
          # Inverse association
          inverse = inverse_of(association)
          # We first check the model doesn't have an association already created to the tenant
          # We may have one but with a different name, and we don't care
          if inverse.present?
            assoc = inverse.name
          else
            raise DirectAssociationNotConfigured, "Class #{klass.name} is 1 degree from #{self.name} but the association isn't configured, you should implement it before using tenant method"
          end
        
        # The coming class has a relationship to the tenant
        else
          # If already created, we don't need to go further
          return singular_association_name if klass.new.respond_to?(singular_association_name)
          return plural_association_name if klass.new.respond_to?(plural_association_name)
          
          # Inverse association
          inverse = inverse_of(association)
          
          # If no inverse, we cannot go further
          if inverse.nil?
            raise InverseAssociationNotConfigured, "Assocation #{association.name} on #{association.klass.name} could not be configured correctly as no inverse has been found"
          elsif inverse.options.has_key? :polymorphic
            return nil
          end
            

          # Common options
          options = {
            through: inverse.name,
            autosave: false
          }
          
          # If the target is linked through some sort of has_many
          if link == plural_association_name || inverse.collection?
            # Has many
            assoc = plural_association_name
            # Setup the association
            # Setup the scope with_name_of_plural_associations
            # Current tenant table name
            klass.has_many assoc, options
            
            Strongbolt.logger.debug "#{klass.name} has_many #{plural_association_name} through: #{options[:through]}\n\n"

          # Otherwise, it's linked through a has one
          else
            # Has one
            assoc = singular_association_name
            # Setup the association
            # Setup the scope with_name_of_plural_associations
            klass.has_one assoc, options
            
            Strongbolt.logger.debug "#{klass.name} has_one #{singular_association_name} through: #{options[:through]}\n\n"
          end
        end

        #
        # Now includes scopes
        #
        klass.class_exec(plural_association_name, assoc, table_name) do |plur, assoc, table_name|
          scope "with_#{plur}", -> { includes assoc }

          scope "where_#{plur}_among", ->(values) do
              if values.is_a? Array
                # If objects
                values = values.map(&:id) if values.first.respond_to? :id
              else
                # If object
                values = values.id if values.respond_to?(:id)
              end

              includes(assoc).where(table_name => {id: values})
            end
        end

        # And return name of association
        return assoc
      end #/setup_model


      #
      # The initial idea of using a polymorphic association on UsersTenant
      # leads to some problems* when the tenant is a subclass of a STI schema
      # and not the whole schema. Using instead STI for the UsersTenant model
      # allows to achieve the same results without the edge effects.
      #
      # *For instance, let's say we have a Resource STI model, with Client
      # and User as subclasses. Client is a tenant, User is not.
      # If using the original idea of polymorphic association on UsersTenant,
      # Helpers like user.client_ids = [5] wouldn't work.
      # This comes from the fact that AR use the base_class name of the STI model
      # and not the actual class name to be stored in the _type column.
      #
      #
      def create_users_tenant_subclass
        unless Strongbolt.const_defined?("Users#{self.name}")
          users_tenant_subclass = Class.new(Strongbolt::UsersTenant)
          users_tenant_subclass.class_eval <<-RUBY
            # Ensures permissions on UsersTenant are applied here
            authorize_as "Strongbolt::UsersTenant"
            # The association to the actual tenant model
            belongs_to :#{singular_association_name},
              :foreign_key => :tenant_id,
              :class_name => "#{self.name}"

            # We have to create this association every time to have
            # The correct inverse_of
            belongs_to :user, class_name: Configuration.user_class,
              :inverse_of => :users_#{plural_association_name}

            validates :#{singular_association_name}, :presence => true
          RUBY
          Strongbolt.const_set "Users#{self.name}", users_tenant_subclass
        end
      end #/create_users_tenant_subclass

      #
      # Setups the has_many thru association on the User class
      #
      def setup_association_on_user
        begin
          user_class = Configuration.user_class.constantize

          # Setup the association
          # The first one should never be there before
          user_class.has_many :"users_#{plural_association_name}",
            :class_name => "Strongbolt::Users#{self.name}",
            :inverse_of => :user,
            :dependent => :delete_all

          # This one may have been overriden by the developer
          unless user_class.respond_to? plural_association_name
            user_class.has_many plural_association_name,
              :source => :"#{singular_association_name}",
              :class_name => self.name,
              :through => :"users_#{plural_association_name}"
          end

          # Setup a quick method to get accessible clients directly
          unless user_class.respond_to? "accessible_#{plural_association_name}"
            user_class.class_exec(self, plural_association_name) do |klass, plur|
              define_method "accessible_#{plur}" do
                # If can find ALL the tenants
                if can? :find, klass, :any, true
                  # Then it can access all of them
                  klass.all
                else
                  # Otherwise, only the ones he manages
                  send plur
                end
              end
            end
          end
        rescue NameError => e
          Strongbolt.logger.error "User #{Configuration.user_class} could not have his association to tenant #{name} created"
        end
      end #/setup_association_on_user

      #
      # Returns the inverse of specified association, using what's given
      # as inverse_of or trying to guess it
      #
      def inverse_of association
        # If specified in association configuration
        return association.inverse_of if association.has_inverse?

        polymorphic_associations = []

        # Else we need to find it, using the class as reference
        association.klass.reflect_on_all_associations.each do |assoc|
          # If the association is polymorphic
          if assoc.options.has_key? :polymorphic
            polymorphic_associations << assoc

          # If same class than the original source of the association
          elsif assoc.klass == association.active_record

            Strongbolt.logger.debug "Selected inverse of #{association.name} between #{association.active_record} " +
              "and #{association.klass} is #{assoc.name}.\n " +
              "If not, please configure manually the inverse of #{association.name}\n"

            return assoc
          end
        end

        if polymorphic_associations.size == 1
          return polymorphic_associations.first
        end

        return nil
      end

      #
      # Returns true if should visit the association
      #
      # The BFS should visit the next model if the model hasn't been visited yet
      # or was already visited but through a polymorphic association (hence no inverse)
      # if the model is a HasMany, HasManyAndBelongsTo or HasOne association (ie no BelongsTo)
      # and not HasManyThrough, unless it's AR v >= 4.1.0 && < 4.2.0 where
      # they define a HasManyAndBelongsTo as a HasManyThrough in the reflections
      #
      def should_visit? association
        ! (association.is_a?(ActiveRecord::Reflection::ThroughReflection) ||
            association.macro == :belongs_to ||
            (@models_traversed.has_key?(association.klass.name) &&
              @models_traversed[association.klass.name].present?) )
      end

    end
    
    module InstanceMethods
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end