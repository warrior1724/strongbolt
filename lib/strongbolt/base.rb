module Strongbolt
  class Base < ActiveRecord::Base
    include Bolted

    self.abstract_class = true
  end
end
