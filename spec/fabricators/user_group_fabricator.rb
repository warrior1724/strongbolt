Fabricator(:user_group, class_name: "Strongbolt::UserGroup") do
  name          { sequence(:name) { |i| "User Group #{i}" } }
end

Fabricator(:user_group_with_roles, from: :user_group) do
  after_build do |user_group|
    user_group.roles << Fabricate(:role)
  end
end