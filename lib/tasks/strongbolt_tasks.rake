namespace :strongbolt do
  #
  # Create full authorization roles that allows to get started using StrongBolt
  #
  task seed: :environment do
    ActiveRecord::Base.transaction do
      #
      # Creates capabilities for all models/actions
      #
      Strongbolt::Capability.models.each do |model|
        Strongbolt::Capability::Actions.each do |action|
          Strongbolt::Capability.where(model: model, action: action,
                                       require_tenant_access: false).first_or_create
        end
      end

      # The role
      role = Strongbolt::Role.create! name: 'FULL ACCESS (TEMPORARY)'
      role.capabilities = Strongbolt::Capability.all

      # The user group
      ug = Strongbolt::UserGroup.create! name: 'FULL ACCESS USERS (TEMPORARY)'
      ug.roles << role

      # Assign to all users
      User.all.each { |user| user.user_groups << ug }
    end
  end
end
