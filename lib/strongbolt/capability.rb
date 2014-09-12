module StrongBolt
  class Capability < ActiveRecord::Base

    has_and_belongs_to_many :roles, class_name: "StrongBolt::Role"
    has_many :users, through: :roles

    validates :model, :action, presence: true
    validates :action, inclusion: %w{find create update destroy}
    validate :model_exists?


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
  end
end

Capability = StrongBolt::Capability unless defined? Capability