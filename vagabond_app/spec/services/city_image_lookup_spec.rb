require "rails_helper"

RSpec.describe CityImageLookup do
  # JPEG magic bytes so Marcel detects image/jpeg without a real download.
  let(:image_bytes) { "\xFF\xD8\xFF\xE0image-data".b }

  def stub_http(responses)
    allow_any_instance_of(described_class).to receive(:http_get) do |_instance, uri, **|
      key = responses.keys.find { |k| uri.to_s.match?(k) }
      raise "unexpected request: #{uri}" unless key

      responses[key]
    end
  end

  it "returns nil for a blank name" do
    expect(described_class.call("  ")).to be_nil
  end

  it "uses the Wikipedia lead photo when it is a real image" do
    stub_http(
      /wikipedia/ => { originalimage: { source: "https://img/London_Skyline.jpg" } }.to_json,
      /London_Skyline/ => image_bytes
    )
    result = described_class.call("London")
    expect(result.source_url).to end_with("London_Skyline.jpg")
    expect(result.content_type).to eq("image/jpeg")
  end

  it "rejects a Wikipedia flag/seal image and falls back to Openverse" do
    stub_http(
      /wikipedia/ => { originalimage: { source: "https://img/Flag_of_Gibraltar.png" } }.to_json,
      /openverse/ => { results: [ { url: "https://flickr/gibraltar.jpg" } ] }.to_json,
      %r{flickr/gibraltar} => image_bytes
    )
    expect(described_class.call("Gibraltar").source_url).to eq("https://flickr/gibraltar.jpg")
  end

  it "falls back to Picsum when both lookups miss" do
    stub_http(
      /wikipedia/ => { title: "Nowhere" }.to_json,   # no image keys
      /openverse/ => { results: [] }.to_json,
      /picsum/ => image_bytes
    )
    expect(described_class.call("Atlantis").source_url).to match(%r{picsum\.photos/seed/atlantis})
  end

  it "swallows network errors and returns nil" do
    allow_any_instance_of(described_class).to receive(:http_get).and_raise(SocketError)
    expect(described_class.call("London")).to be_nil
  end
end
