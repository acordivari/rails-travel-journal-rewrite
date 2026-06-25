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

  describe "#attach_stock_image!" do
    it "attaches the image returned by CityImageLookup" do
      city = create(:city)
      result = CityImageLookup::Result.new(
        io: StringIO.new("img"), filename: "x.jpg", content_type: "image/jpeg"
      )
      allow(CityImageLookup).to receive(:call).with(city.name).and_return(result)

      expect { city.attach_stock_image! }.to change { city.image.attached? }.from(false).to(true)
    end

    it "is a no-op when an image is already attached" do
      city = create(:city)
      city.image.attach(io: StringIO.new("img"), filename: "x.jpg", content_type: "image/jpeg")
      expect(CityImageLookup).not_to receive(:call)
      expect(city.attach_stock_image!).to be(false)
    end

    it "returns false when the lookup finds nothing" do
      city = create(:city)
      allow(CityImageLookup).to receive(:call).and_return(nil)
      expect(city.attach_stock_image!).to be(false)
    end
  end
end
