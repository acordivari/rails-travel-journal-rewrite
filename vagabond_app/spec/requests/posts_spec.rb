require "rails_helper"

RSpec.describe "Posts", type: :request do
  let(:city)   { create(:city) }
  let(:author) { create(:user) }
  let(:other)  { create(:user) }
  let(:admin)  { create(:user, :admin) }

  it "shows a post publicly" do
    post = create(:post, city: city)
    get post_path(post)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(post.title)
  end

  describe "creation" do
    it "requires login" do
      expect {
        post city_posts_path(city), params: { post: { title: "T", body: "B" } }
      }.not_to change(Post, :count)
      expect(response).to redirect_to(new_session_path)
    end

    it "creates a post owned by the current user" do
      sign_in(author)
      expect {
        post city_posts_path(city), params: { post: { title: "My trip", body: "It was great." } }
      }.to change(Post, :count).by(1)
      expect(Post.last.user).to eq(author)
      expect(Post.last.city).to eq(city)
    end

    it "re-renders with errors on invalid params" do
      sign_in(author)
      post city_posts_path(city), params: { post: { title: "", body: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "authorization for edit/update/destroy" do
    let!(:post_record) { create(:post, user: author, city: city) }

    it "blocks a non-owner from updating" do
      sign_in(other)
      patch post_path(post_record), params: { post: { title: "Hijacked" } }
      expect(response).to redirect_to(root_path)
      expect(post_record.reload.title).not_to eq("Hijacked")
    end

    it "lets the owner update" do
      sign_in(author)
      patch post_path(post_record), params: { post: { title: "Edited" } }
      expect(response).to redirect_to(post_path(post_record))
      expect(post_record.reload.title).to eq("Edited")
    end

    it "blocks a non-owner from deleting" do
      sign_in(other)
      expect { delete post_path(post_record) }.not_to change(Post, :count)
      expect(response).to redirect_to(root_path)
    end

    it "lets an admin delete any post" do
      sign_in(admin)
      expect { delete post_path(post_record) }.to change(Post, :count).by(-1)
    end
  end
end
