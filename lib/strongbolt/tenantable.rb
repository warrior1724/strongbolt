module StrongBolt
  module Tenantable
    module ClassMethods
      #
      # Specifies that the class can be tenanted
      # It will traverse all the has_many relationships
      # and add a has_one :tenant if not specified
      #
      def tenant opts = {}
        # Stops if already configured
        return if tenant?
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
          # Also we don't go following belongs_to relationship, it becomes crazy
          unless @models_traversed.has_key?(current_association.klass.name) ||
            current_association.is_a?(ActiveRecord::Reflection::ThroughReflection) ||
            current_association.macro == :belongs_to
            # We setup the model using the association given
            method = setup_model(current_association)
            # We flag the model, storing the name of the method used to link to tenant
            @models_traversed[current_association.klass.name] = method
            # And add its relationships into the array, at the end
            models_to_traverse.concat current_association.klass.reflect_on_all_associations
          end
        end

        setup_association_on_user

        @tenant = true
        StrongBolt.add_tenant self
      end

      def tenant?() @tenant.present? && @tenant; end

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
        # Inverse association
        inverse = inverse_of(association)

        # If the original class is the actual tenant, it should have defined
        # the reverse association as we cannot guess it
        if original_class == self
          # We first check the model doesn't have an association already created to the tenant
          # We may have one but with a different name, and we don't care
          if inverse.present?
            # We create the scope
            klass.scope "with_#{plural_association_name}", -> { includes inverse.name }
            return inverse.name
          end

          raise DirectAssociationNotConfigured, "Class #{klass.name} is 1 degree from #{self.name} but the association isn't configured, you should implement it before using tenant method"
        
        # The coming class has a relationship to the tenant
        else
          # If already created, we don't need to go further
          return singular_association_name if klass.new.respond_to?(singular_association_name)
          return plural_association_name if klass.new.respond_to?(plural_association_name)
          
          # If no inverse, we cannot go further
          unless inverse.present?
            raise InverseAssociationNotConfigured, "Assocation #{association.name} on #{association.klass.name} could not be configured correctly as no inverse has been found"
          end

          # Common options
          options = {
            through: inverse.name
          }
          
          # If the target is linked through some sort of has_many
          if link == plural_association_name || inverse.collection?
            # Setup the association
            klass.has_many plural_association_name, options
            # Setup the scope with_name_of_plural_associations
            klass.scope "with_#{plural_association_name}", -> { includes plural_association_name }
            
            puts "#{klass.name} has_many #{plural_association_name} through: #{options[:through]}"
            return plural_association_name

          # Otherwise, it's linked through a has one
          else
            # Setup the association
            klass.has_one singular_association_name, options
            # Setup the scope with_name_of_plural_associations
            klass.scope "with_#{plural_association_name}", -> { includes singular_association_name }
            
            puts "#{klass.name} has_one #{singular_association_name} through: #{options[:through]}"
            return singular_association_name
          end 
        end
      end

      #
      # Setups the has_many thru association on the User class
      #
      def setup_association_on_user
        Configuration.user_class.constantize.has_many plural_association_name,
          :source => :tenant,
          :source_type => self.name,
          :through => :users_tenants
      end

      #
      # Returns the inverse of specified association, using what's given
      # as inverse_of or trying to guess it
      #
      def inverse_of association
        # If specified in association configuration
        return association.inverse_of if association.has_inverse?


        # Else we need to find it, using the class as reference
        association.klass.reflect_on_all_associations.each do |assoc|
          # If same class than the original source of the association
          if assoc.klass == association.active_record

            puts "Association #{association.name} between #{association.active_record} " +
              "and #{association.klass} don't have any inverse configured, " +
              "#{assoc.name} was selected as inverse. If it is not, please configure manually " +
              "the inverse of #{association.name}"

            return assoc
          end
        end

        return nil
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