require "rails_helper"

RSpec.describe "Cities", type: :request do
  let(:user)  { create(:user) }
  let(:admin) { create(:user, :admin) }

  it "lists cities publicly" do
    create(:city, name: "Oslo")
    get cities_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Oslo")
  end

  describe "creation (admin only)" do
    it "blocks a guest" do
      get new_city_path
      expect(response).to redirect_to(new_session_path)
    end

    it "blocks a non-admin" do
      sign_in(user)
      expect {
        post cities_path, params: { city: { name: "Sneaky" } }
      }.not_to change(City, :count)
      expect(response).to redirect_to(root_path)
    end

    it "allows an admin" do
      sign_in(admin)
      expect {
        post cities_path, params: { city: { name: "Reykjavik" } }
      }.to change(City, :count).by(1)
    end
  end

  describe "deletion (admin only)" do
    it "blocks a non-admin" do
      city = create(:city)
      sign_in(user)
      expect { delete city_path(city) }.not_to change(City, :count)
      expect(response).to redirect_to(root_path)
    end

    it "allows an admin" do
      city = create(:city)
      sign_in(admin)
      expect { delete city_path(city) }.to change(City, :count).by(-1)
    end
  end
end
