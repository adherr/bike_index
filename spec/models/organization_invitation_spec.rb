require "spec_helper"

describe OrganizationInvitation do

  describe :validations do
    it { should belong_to :inviter }
    it { should belong_to :invitee }
    it { should validate_presence_of :invitee_email }
    it { should validate_presence_of :organization }
    it { should validate_presence_of :inviter }
    it { should validate_presence_of :membership_role }
  end  

  describe :create do
    before :each do
      @o = FactoryGirl.create(:organization_invitation)
    end

    it "should create a valid organization_invitation" do 
      @o.valid?.should be_true
    end

    it "should enqueue an email job" do
      OrganizationInvitationEmailJob.should have_queued(@o.id)
    end

    it "should assign to user if the user exists" do 
      @user = FactoryGirl.create(:user)
      @o1 = FactoryGirl.create(:organization_invitation, invitee_email: @user.email)
      @user.memberships.count.should eq(1)
      @o1.redeemed.should be_true
    end
  end

  describe :normalize_email do 
    it "should remove leading and trailing whitespace and downcase email" do 
      oi = OrganizationInvitation.new 
      oi.stub(:invitee_email).and_return("   SomE@dd.com ")
      oi.normalize_email.should eq("some@dd.com")
    end
  end
  

  describe "assign_to(user)" do 

    before :each do
      @organization = FactoryGirl.create(:organization)
      @o = FactoryGirl.create(:organization_invitation, organization: @organization, invitee_email: "EMAIL@email.com")
      @user = FactoryGirl.create(:user, email: "EMAIL@email.com")
    end

    it "should set the user if the email does match" do
      @o.assign_to(@user)
      @o.invitee.id.should eq(@user.id)
    end

    it "should set the user's name if the name is blank" do
      @user2 = FactoryGirl.create(:user, name: nil)
      @o2 = FactoryGirl.create(:organization_invitation, organization: @organization, invitee_email: @user2.email, invitee_name: "Biker Name")
      @o2.assign_to(@user2)
      @user2.reload.name.should eq("Biker Name")
    end

    it "should not be able to be used again once it has been redeemed" do
      @o.assign_to(@user)
      @o.assign_to(@user)
      @user.memberships.count.should eq(1)
    end

    it "should redeem the invitation" do
      @o.assign_to(@user)
      @o.redeemed.should be_true
    end

    it "should not let users have more than one membership to a single organization" do
      FactoryGirl.create(:membership, organization: @organization, user: @user)
      # pp @user.organizations
      @o.assign_to(@user)
      @user.memberships.count.should eq(1)
    end

    it "should let users have multiple memberships to different organizations" do
      @organization2 = FactoryGirl.create(:organization)
      FactoryGirl.create(:membership, organization: @organization2, user: @user)
      @o.assign_to(@user)
      @user.memberships.count.should eq(2)
    end
    
    it "should create a membership on assignment" do
      @o2 = FactoryGirl.create(:organization_invitation, organization: @organization, invitee_email: "George@gma.com")
      @user2 = FactoryGirl.create(:user, email: "george@gma.com")
      lambda {
        @o2.assign_to(@user2)
      }.should change(Membership, :count).by(1)
    end
  end

end
