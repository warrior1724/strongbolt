module StrongBolt
  StrongBoltError = Class.new StandardError
  Unauthorized = Class.new StrongBoltError
  
  ModelNotFound = Class.new StrongBoltError
  ActionNotConfigured = Class.new StrongBoltError

  WrongUserClass = Class.new StrongBoltError
  ModelNotOwned = Class.new StrongBoltError

  TenantError = Class.new StrongBoltError
  InverseAssociationNotConfigured = Class.new TenantError
  DirectAssociationNotConfigured = Class.new TenantError
end