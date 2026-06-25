# Seed data for Vagabond. Idempotent-ish: clears existing records first so
# `bin/rails db:seed` can be re-run during development.

puts "Clearing existing data..."
Comment.destroy_all
Post.destroy_all
City.destroy_all
User.destroy_all

SEED_IMAGE_DIR = Rails.root.join("db", "seed_images")

def attach_image(record, attachment, filename)
  path = SEED_IMAGE_DIR.join(filename)
  return unless File.exist?(path)

  record.public_send(attachment).attach(
    io: File.open(path),
    filename: filename,
    content_type: Marcel::MimeType.for(path)
  )
end

puts "Creating users..."
alex = User.create!(name: "Alex Rivera", current_city: "San Francisco",
                    email: "alex@example.com", password: "password", admin: true)
mai  = User.create!(name: "Mai Tanaka", current_city: "London",
                    email: "mai@example.com", password: "password")
sam  = User.create!(name: "Sam Okafor", current_city: "Gibraltar",
                    email: "sam@example.com", password: "password")

puts "Creating cities..."
# Each city pulls a stock photo by name via CityImageLookup (Wikipedia → Picsum).
# If the lookup fails (e.g. offline), we fall back to a bundled local image.
cities = {
  "San Francisco" => "sf.png",
  "London"        => "london.jpg",
  "Gibraltar"     => "gibraltar.jpg"
}.map do |name, fallback_image|
  city = City.create!(name: name)
  if city.attach_stock_image!
    puts "  #{name}: pulled stock image"
  else
    attach_image(city, :image, fallback_image)
    puts "  #{name}: used local fallback image"
  end
  city
end
sf, london, gibraltar = cities

puts "Creating posts..."
posts = [
  { city: sf,        user: alex, title: "Sunset over the Golden Gate",
    body: "Caught the fog rolling in from Baker Beach this evening. The way the light hits the bridge towers never gets old — bring a windbreaker, it gets cold fast once the sun drops." },
  { city: sf,        user: mai,  title: "Best dumplings in the Richmond",
    body: "Spent the afternoon hopping between hole-in-the-wall spots on Clement Street. Cash only at most of them, but worth every dollar." },
  { city: london,    user: mai,  title: "A rainy day in the British Museum",
    body: "Free entry and you could spend a week here. The Reading Room alone is worth the trip. Go early to beat the school groups." },
  { city: london,    user: sam,  title: "Walking the South Bank at night",
    body: "From the Globe to the Eye, the river path is magic after dark. Street performers, food stalls, and the skyline lit up across the water." },
  { city: gibraltar, user: sam,  title: "Meeting the macaques on the Rock",
    body: "The Barbary macaques run the Upper Rock and they know it. Keep your snacks zipped away — they will help themselves. The views into two continents are unreal." },
  { city: gibraltar, user: alex, title: "St. Michael's Cave is otherworldly",
    body: "A natural cathedral of stalactites now used as a concert venue. The light show is a bit kitschy but the scale of the chambers is genuinely breathtaking." }
]

posts.each do |attrs|
  attrs[:city].posts.create!(user: attrs[:user], title: attrs[:title], body: attrs[:body])
end

puts "Creating comments..."
first_post = Post.recent.last
first_post.comments.create!(user: mai, body: "Adding this to my list for next trip!")
first_post.comments.create!(user: sam, body: "The fog really is something else out there.")

puts "Done. #{User.count} users, #{City.count} cities, #{Post.count} posts, #{Comment.count} comments."
