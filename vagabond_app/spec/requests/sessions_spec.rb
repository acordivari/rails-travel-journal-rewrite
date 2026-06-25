require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) { create(:user, email: "log@in.com", password: "password") }

  it "logs in with valid credentials" do
    post session_path, params: { email: "log@in.com", password: "password" }
    expect(response).to redirect_to(user_path(user))
    follow_redirect!
    expect(response.body).to include("Welcome back")
  end

  it "rejects invalid credentials and re-renders the form" do
    post session_path, params: { email: "log@in.com", password: "wrong" }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Invalid email or password")
  end

  it "logs out" do
    sign_in(user)
    delete logout_path
    expect(response).to redirect_to(root_path)
  end
end
