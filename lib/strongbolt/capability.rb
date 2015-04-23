module Strongbolt
  class Capability < ActiveRecord::Base

    Actions = %w{find create update destroy}

    DEFAULT_MODELS = ["Strongbolt::UserGroup",
      "Strongbolt::Role",
      "Strongbolt::Capability",
      "Strongbolt::UsersTenant"]

    has_and_belongs_to_many :roles, class_name: "Strongbolt::Role"
    has_many :users, through: :roles

    validates :model, :action, presence: true
    validates :action, inclusion: Actions,
      uniqueness: {scope: [:model, :require_ownership, :require_tenant_access]}
    validate :model_exists?

    before_destroy :should_not_have_roles

    before_validation :set_default
    after_initialize :set_default

    #
    # List all the models to be used in capabilities
    #
    def self.models() @models ||= DEFAULT_MODELS; end
    def self.models=(models) @models = models; end

    def self.add_models models
      @models ||= DEFAULT_MODELS
      @models |= [*models]
      @models.sort!
    end

    scope :ordered, -> {
      select("#{self.table_name}.*")
        .select("CASE WHEN action = 'find' THEN 0 " +
                "WHEN action = 'create' THEN 1 " +
                "WHEN action = 'update' THEN 2 " +
                "WHEN action = 'destroy' THEN 3 END AS action_id")
        .order(:model, :require_ownership, :require_tenant_access, 'action_id')
    }

    #
    # Group by model, ownership and tenant access
    # and tells whether each action is set or not
    #
    def self.to_table
      table = []
      all.ordered.each do |capability|
        if table.last.nil? ||
          ! (table.last[:model] == capability.model &&
            table.last[:require_ownership] == capability.require_ownership &&
            table.last[:require_tenant_access] == capability.require_tenant_access)
          
          table << {
            model: capability.model,
            require_ownership: capability.require_ownership,
            require_tenant_access: capability.require_tenant_access,
            find: false,
            create: false,
            update: false,
            destroy: false
          }
        end

        table.last[capability.action.to_sym] = true
      end
      table
    end

    #
    # Group by model, ownership and tenant access
    # and tells whether each action is set or not
    # in a hash
    #
    def self.to_hash
      hash = {}
      all.ordered.each do |capability|
        key = {
          model: capability.model,
          require_ownership: capability.require_ownership,
          require_tenant_access: capability.require_tenant_access
        }
        
        hash[key] ||= {
          find: false,
          create: false,
          update: false,
          destroy: false
        }

        hash[key][capability.action.to_sym] = true
      end
      hash
    end



    #
    # Create a set capabilities from a hash
    # which has:
    # {
    #   model: "ModelName",
    #   require_ownership: true,
    #   require_tenant_access: false,
    #   actions: [:find, :update]}
    #
    # Actions can be either one operation, an array of operations,
    # or :all meaning all operations
    #
    def self.from_hash hash
      hash.symbolize_keys!
      actions_from_list(hash[:actions]).map do |action|
        new :model => hash[:model],
          :require_ownership => hash[:require_ownership],
          :require_tenant_access => hash[:require_tenant_access],
          :action => action
      end
    end

    #
    # Virtual setter of actions
    #
    def self.actions_from_list actions
      # Transform actions array
      if actions.respond_to?(:to_sym) && actions.to_sym == :all
        Actions # All actions
      else
        [*actions] # Transform into an array
      end
    end

    private

    #
    # Checks that the model given as a string exists
    #
    def model_exists?
      if model.present?
        begin
          model.constantize
        rescue NameError => e
          errors.add :model, "#{model} is not a valid model"
        end
      end
    end

    #
    # Should not have roles
    #
    def should_not_have_roles
      if roles.size > 0
        raise ActiveRecord::DeleteRestrictionError.new :roles
      end
    end

    #
    # Default parameters
    #
    def set_default
      self.require_ownership = true if require_ownership.nil?
      self.require_tenant_access = true if require_tenant_access.nil?
      true # Ensures it passes
    end
  end
end

Capability = Strongbolt::Capability unless defined? Capability