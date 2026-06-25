require "rails_helper"

RSpec.describe City, type: :model do
  it "has a valid factory" do
    expect(build(:city)).to be_valid
  end

  it "requires a name" do
    expect(build(:city, name: nil)).not_to be_valid
  end

  it "enforces case-insensitive name uniqueness" do
    create(:city, name: "Porto")
    expect(build(:city, name: "porto")).not_to be_valid
  end

  it "destroys dependent posts" do
    city = create(:city)
    create(:post, city: city)
    expect { city.destroy }.to change(Post, :count).by(-1)
  end
end
