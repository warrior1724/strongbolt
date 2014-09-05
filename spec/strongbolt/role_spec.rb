require "spec_helper"

module StrongBolt

  describe Role do
    
    let(:role) { Role.new name: 'Moderator' }

    subject { role }

    it { should be_valid }

    it { should validate_presence_of :name }

    it { should have_and_belong_to_many :user_groups }
    it { should have_many(:users).through :user_groups  }
    it { should have_and_belong_to_many :capabilities }

  end

end