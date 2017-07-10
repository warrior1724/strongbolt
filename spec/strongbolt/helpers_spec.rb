require 'spec_helper'
require 'strongbolt/helpers'

describe Strongbolt::Helpers do
  before do
    @user = User.create!

    define('Helper', Object) do
      include Strongbolt::Helpers
    end

    Helper.class_exec(@user) do |user|
      define_method :current_user do
        user
      end
    end
  end

  let(:user) { @user }
  let(:helper) { Helper.new }

  describe 'can?' do
    before do
      expect(user).to receive(:can?).with :find, 'me'
    end

    it 'should call the user method' do
      helper.can?(:find) { 'me' }
    end
  end

  describe 'cannot?' do
    before do
      expect(user).to receive(:can?).with :find, 'me'
    end

    it 'should call the user method' do
      helper.cannot? :find, 'me'
    end
  end
end
