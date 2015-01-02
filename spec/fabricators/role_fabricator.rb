Fabricator(:role, class_name: "Strongbolt::Role") do
  name              { sequence(:name) { |i| "Role #{i}" } }
end

Fabricator(:role_with_user_groups, from: :role) do
  after_build do |role|
    role.user_groups << Fabricate(:user_group)
  end
end