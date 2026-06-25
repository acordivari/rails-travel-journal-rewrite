require "rails_helper"

RSpec.describe Post, type: :model do
  it "has a valid factory" do
    expect(build(:post)).to be_valid
  end

  it "requires a user and a city" do
    expect(build(:post, user: nil)).not_to be_valid
    expect(build(:post, city: nil)).not_to be_valid
  end

  it "requires a title and body" do
    expect(build(:post, title: nil)).not_to be_valid
    expect(build(:post, body: nil)).not_to be_valid
  end

  it "limits title length to 200 characters" do
    expect(build(:post, title: "x" * 201)).not_to be_valid
  end

  it "destroys dependent comments" do
    post = create(:post)
    create(:comment, post: post)
    expect { post.destroy }.to change(Comment, :count).by(-1)
  end

  describe "#excerpt" do
    it "truncates a long body" do
      post = build(:post, body: "word " * 100)
      expect(post.excerpt(20).length).to be <= 20
    end
  end
end
