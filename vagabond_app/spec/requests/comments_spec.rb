require "rails_helper"

RSpec.describe "Comments", type: :request do
  let(:post_record) { create(:post) }
  let(:author)      { create(:user) }
  let(:other)       { create(:user) }
  let(:admin)       { create(:user, :admin) }

  describe "creation" do
    it "requires login" do
      expect {
        post post_comments_path(post_record), params: { comment: { body: "Hi" } }
      }.not_to change(Comment, :count)
      expect(response).to redirect_to(new_session_path)
    end

    it "creates a comment for the current user" do
      sign_in(author)
      expect {
        post post_comments_path(post_record), params: { comment: { body: "Nice post" } }
      }.to change(Comment, :count).by(1)
      expect(Comment.last.user).to eq(author)
    end
  end

  describe "deletion" do
    let!(:comment) { create(:comment, post: post_record, user: author) }

    it "blocks a non-owner, non-admin" do
      sign_in(other)
      expect { delete comment_path(comment) }.not_to change(Comment, :count)
      expect(response).to redirect_to(root_path)
    end

    it "lets the owner delete" do
      sign_in(author)
      expect { delete comment_path(comment) }.to change(Comment, :count).by(-1)
    end

    it "lets an admin delete" do
      sign_in(admin)
      expect { delete comment_path(comment) }.to change(Comment, :count).by(-1)
    end
  end
end
