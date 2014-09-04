module GrantHelpers
  def without_grant &block
    Grant::Status.without_grant &block
  end
end