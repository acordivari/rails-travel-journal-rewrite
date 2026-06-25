require "rails_helper"

RSpec.describe "Users", type: :request do
  describe "POST /users" do
    it "creates a user and logs them in with valid params" do
      expect {
        post users_path, params: { user: { name: "New", email: "new@example.com", password: "password" } }
      }.to change(User, :count).by(1)
      expect(response).to redirect_to(user_path(User.last))
    end

    # Regression test: the legacy controller rendered a blank page on failure.
    it "re-renders the form with errors on invalid params" do
      expect {
        post users_path, params: { user: { name: "", email: "bad", password: "" } }
      }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("error")
    end
  end

  describe "authorization" do
    let(:owner)     { create(:user) }
    let(:other)     { create(:user) }
    let(:admin)     { create(:user, :admin) }

    # Regression test: the legacy #update had NO authorization check.
    it "blocks a non-owner from updating another user" do
      sign_in(other)
      patch user_path(owner), params: { user: { name: "Hacked" } }
      expect(response).to redirect_to(root_path)
      expect(owner.reload.name).not_to eq("Hacked")
    end

    it "blocks a guest from updating a user" do
      patch user_path(owner), params: { user: { name: "Hacked" } }
      expect(response).to redirect_to(new_session_path)
      expect(owner.reload.name).not_to eq("Hacked")
    end

    it "lets the owner update their own profile" do
      sign_in(owner)
      patch user_path(owner), params: { user: { name: "Renamed" } }
      expect(response).to redirect_to(user_path(owner))
      expect(owner.reload.name).to eq("Renamed")
    end

    it "blocks a non-admin, non-owner from deleting a user" do
      target = owner # create before the block so only the delete could change the count
      sign_in(other)
      expect { delete user_path(target) }.not_to change(User, :count)
      expect(response).to redirect_to(root_path)
    end

    it "lets an admin delete any user" do
      user_to_remove = create(:user)
      sign_in(admin)
      expect { delete user_path(user_to_remove) }.to change(User, :count).by(-1)
    end
  end
end
