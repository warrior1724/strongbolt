require "spec_helper"
require "strongbolt/controllers/url_helpers"

module Strongbolt
  module Controllers
    describe UrlHelpers do
      
      let(:helpersClass) do
        Class.new do
          def main_app; end
        end
      end

      before { helpersClass.send :include, UrlHelpers }

      let(:helpers) { helpersClass.new }

      subject { helpers }

      it { should respond_to :new_role_path }

      describe "edit_role_path" do
        let(:main_app) { double("main_app", :edit_strongbolt_role_path => true) }
        
        it "should call new_strongbolt_role_path on the main app" do
          expect(helpers).to receive(:main_app).and_return main_app
          expect(main_app).to receive(:edit_strongbolt_role_path).with 2
          helpers.edit_role_path 2
        end
      end

    end
  end
end