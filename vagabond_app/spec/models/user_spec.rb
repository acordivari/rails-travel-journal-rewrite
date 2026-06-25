require "rails_helper"

RSpec.describe User, type: :model do
  it "has a valid factory" do
    expect(build(:user)).to be_valid
  end

  it "requires a name" do
    expect(build(:user, name: nil)).not_to be_valid
  end

  it "requires a well-formed email" do
    expect(build(:user, email: "not-an-email")).not_to be_valid
  end

  it "normalizes email to lowercase and strips whitespace" do
    user = create(:user, email: "  Mixed@Case.COM ")
    expect(user.email).to eq("mixed@case.com")
  end

  it "enforces case-insensitive email uniqueness" do
    create(:user, email: "dup@example.com")
    expect(build(:user, email: "DUP@example.com")).not_to be_valid
  end

  it "stores a password digest, not the password" do
    user = create(:user, password: "secret123")
    expect(user.password_digest).to be_present
    expect(user.authenticate("secret123")).to eq(user)
    expect(user.authenticate("wrong")).to be(false)
  end

  describe ".authenticate_by" do
    it "returns the user with correct credentials and nil otherwise" do
      user = create(:user, email: "a@b.com", password: "password")
      expect(User.authenticate_by(email: "a@b.com", password: "password")).to eq(user)
      expect(User.authenticate_by(email: "a@b.com", password: "nope")).to be_nil
    end
  end

  it "destroys dependent posts and comments" do
    user = create(:user)
    create(:post, user: user)
    create(:comment, user: user)
    expect { user.destroy }.to change(Post, :count).by(-1).and change(Comment, :count).by(-1)
  end
end
