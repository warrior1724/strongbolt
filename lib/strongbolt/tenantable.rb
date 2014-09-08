module StrongBolt
  module Tenantable
    module ClassMethods
      #
      # Specifies that the class can be tenanted
      # It will traverse all the has_many relationships
      # and add a has_one :tenant if not specified
      #
      def tenant
        # Stops if already configured
        return if tenant?
        #
        # We're traversing using BFS the relationships
        #
        # Keep track of traversed models and their relationship to the tenant
        @models_traversed = {self => self}
        # File of models/associations to traverse
        models_to_traverse = reflect_on_all_associations
        while models_to_traverse.size > 0
          current_association = models_to_traverse.shift
          # We don't check has_many :through association though,
          # only first degree relationships. It makes sense as we'll
          # obviously also be checking the models concerned with the through
          # relationship, using the intermediate model
          unless @models_traversed.has_key?(current_association.klass) ||
            current_association.is_a?(ActiveRecord::Reflection::ThroughReflection)
            # We setup the model using the association given
            method = setup_model(current_association)
            # We flag the model, storing the name of the method used to link to tenant
            @models_traversed[current_association.klass] = method
            # And add its relationships into the array, at the end
            models_to_traverse.concat current_association.klass.reflect_on_all_associations
          end
        end
        @tenant = true
        StrongBolt.add_tenant self
      end

      def tenant?() @tenant.present? && @tenant; end

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
        link = @models_traversed[original_class]
        # Inverse association
        inverse = inverse_of(association)

        # If the original class is the actual tenant, it should have defined
        # the reverse association as we cannot guess it
        if original_class == self
          # We first check the model doesn't have an association already created to the tenant
          # We may have one but with a different name, and we don't care
          return inverse.name if inverse.present?

          raise AssociationNotConfigured, "Class #{klass.name} is 1 degree from #{self.name} but the association isn't configured, you should implement it before using tenant method"
        
        # The coming class has a relationship to the tenant
        else
          # If already created, we don't need to go further
          return singular_association_name if klass.new.respond_to?(singular_association_name)
          return plural_association_name if klass.new.respond_to?(plural_association_name)
          
          # If no inverse, we cannot go further
          unless inverse.present?
            raise AssociationNotConfigured, "Assocation #{association.name} on #{association.klass.name} could not be configured correctly as no inverse has been found"
          end

          # Common options
          options = {
            through: inverse.name,
            inverse_of: association.name
          }
          
          # If the target is linked through some sort of has_many
          if link == plural_association_name || inverse.macro == :has_and_belongs_to_many || inverse.macro == :has_many
            klass.has_many plural_association_name, options
            puts "#{klass.name} has_many #{plural_association_name} through: #{options[:through]}"
            return plural_association_name

          # Otherwise, it's linked through a has one
          else
            klass.has_one singular_association_name, options
            puts "#{klass.name} has_one #{singular_association_name} through: #{options[:through]}"
            return singular_association_name
          end 
        end
      end

      #
      # Returns associations potential name
      #
      def singular_association_name
        @singular_association_name ||= self.name.demodulize.underscore.to_sym
      end
      def plural_association_name
        @plural_association_name ||= self.name.demodulize.underscore.pluralize.to_sym
      end

      #
      # Returns the inverse of specified association, using what's given
      # as inverse_of or trying to guess it
      #
      def inverse_of association
        # If specified in association configuration
        return association.inverse_of if association.has_inverse?

        # Else we need to find it
        association.klass.reflect_on_all_associations.each do |assoc|
          return assoc if assoc.klass == association.active_record
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