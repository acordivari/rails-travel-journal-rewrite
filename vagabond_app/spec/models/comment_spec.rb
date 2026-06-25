require "rails_helper"

RSpec.describe Comment, type: :model do
  it "has a valid factory" do
    expect(build(:comment)).to be_valid
  end

  it "requires a body" do
    expect(build(:comment, body: nil)).not_to be_valid
  end

  it "requires a user and a post" do
    expect(build(:comment, user: nil)).not_to be_valid
    expect(build(:comment, post: nil)).not_to be_valid
  end
end
