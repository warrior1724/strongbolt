module StrongBolt
  class Capability < ActiveRecord::Base

    Actions = %w{find create update destroy}

    has_and_belongs_to_many :roles, class_name: "StrongBolt::Role"
    has_many :users, through: :roles

    validates :model, :action, presence: true
    validates :action, inclusion: Actions,
      uniqueness: {scope: [:model, :require_ownership, :require_tenant_access]}
    validate :model_exists?

    before_destroy :should_not_have_roles

    #
    # List all the models to be used in capabilities
    #
    def self.models() @models ||= []; end
    def self.models=(models) @models = models; end

    def self.add_models models
      @models ||= []
      @models |= [*models]
      @models.sort!
    end

    scope :ordered, -> {
      order(:model, :require_ownership, :require_tenant_access)
        .select("#{self.table_name}.*")
        .select("CASE WHEN action = 'find' THEN 0 " +
                "WHEN action = 'create' THEN 1 " +
                "WHEN action = 'update' THEN 2 " +
                "WHEN action = 'destroy' THEN 3 END AS action_id")
        .order 'action_id'
    }

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
  end
end

Capability = StrongBolt::Capability unless defined? Capability