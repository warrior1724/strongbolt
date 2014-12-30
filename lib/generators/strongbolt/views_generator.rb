require 'rails/generators/base'

module Strongbolt
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      desc "Copies Strongbolt views to your application."

      argument :scope, required: false, default: nil,
                       desc: "The scope to copy views to"

      public_task :copy_views

      source_root File.expand_path("../../../../app/views", __FILE__)

      def copy_views
        directory :strongbolt, target_path
      end

      protected

      def target_path
        @target_path ||= "app/views/#{scope || :strongbolt}"
      end
    end
  end
end