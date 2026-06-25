# Seed data for Vagabond. Idempotent-ish: clears existing records first so
# `bin/rails db:seed` can be re-run during development.
#
# Cities pull a cover photo by name via CityImageLookup (Wikipedia → Openverse →
# Picsum). This makes ~50 network requests, so seeding takes a little while; set
# SKIP_CITY_IMAGES=1 to seed names only (placeholders shown in the UI).

require "faker"

puts "Clearing existing data..."
Comment.destroy_all
Post.destroy_all
City.destroy_all
User.destroy_all

SEED_IMAGE_DIR = Rails.root.join("db", "seed_images")
SKIP_IMAGES    = ENV["SKIP_CITY_IMAGES"] == "1"

# Local fallbacks (used when a lookup fails or images are skipped).
LOCAL_FALLBACKS = {
  "San Francisco" => "sf.png",
  "London"        => "london.jpg",
  "Gibraltar"     => "gibraltar.jpg"
}.freeze

def attach_image(record, attachment, filename)
  path = SEED_IMAGE_DIR.join(filename)
  return false unless File.exist?(path)

  record.public_send(attachment).attach(
    io: File.open(path),
    filename: filename,
    content_type: Marcel::MimeType.for(path)
  )
  true
end

puts "Creating users..."
users = [
  { name: "Alex Rivera",   current_city: "San Francisco", email: "alex@example.com", admin: true },
  { name: "Mai Tanaka",    current_city: "London",        email: "mai@example.com" },
  { name: "Sam Okafor",    current_city: "Gibraltar",     email: "sam@example.com" },
  { name: "Priya Nair",    current_city: "Singapore",     email: "priya@example.com" },
  { name: "Lucas Moreau",  current_city: "Paris",         email: "lucas@example.com" },
  { name: "Sofia Rossi",   current_city: "Rome",          email: "sofia@example.com" }
].map { |attrs| User.create!(attrs.merge(password: "password")) }
alex, mai, sam = users

# Top tourism destinations around the world.
CITY_NAMES = [
  "Paris", "London", "Rome", "Barcelona", "Amsterdam", "Prague", "Vienna",
  "Venice", "Florence", "Madrid", "Lisbon", "Berlin", "Munich", "Athens",
  "Budapest", "Dublin", "Edinburgh", "Brussels", "Copenhagen", "Stockholm",
  "Reykjavik", "Istanbul", "Dubai", "Bangkok", "Singapore", "Kuala Lumpur",
  "Tokyo", "Kyoto", "Osaka", "Seoul", "Hong Kong", "Shanghai", "Beijing",
  "Bali", "Hanoi", "New York City", "San Francisco", "Los Angeles",
  "Las Vegas", "Chicago", "Toronto", "Vancouver", "Mexico City",
  "Rio de Janeiro", "Buenos Aires", "Cairo", "Marrakech", "Cape Town",
  "Sydney", "Gibraltar"
].freeze

puts "Creating #{CITY_NAMES.size} cities#{' (images skipped)' if SKIP_IMAGES}..."
pulled = 0
cities_by_name = {}
CITY_NAMES.each_with_index do |name, i|
  city = City.create!(name: name)

  unless SKIP_IMAGES
    if city.attach_stock_image!
      pulled += 1
    elsif LOCAL_FALLBACKS[name]
      attach_image(city, :image, LOCAL_FALLBACKS[name])
    end
  end

  cities_by_name[name] = city
  print "\r  #{i + 1}/#{CITY_NAMES.size} cities created (#{pulled} stock images)   "
end
puts

puts "Creating posts..."
# Hand-written posts for a few marquee cities...
curated = [
  { city: "San Francisco", user: alex, title: "Sunset over the Golden Gate",
    body: "Caught the fog rolling in from Baker Beach this evening. The way the light hits the bridge towers never gets old — bring a windbreaker, it gets cold fast once the sun drops." },
  { city: "London", user: mai, title: "A rainy day in the British Museum",
    body: "Free entry and you could spend a week here. The Reading Room alone is worth the trip. Go early to beat the school groups." },
  { city: "Gibraltar", user: sam, title: "Meeting the macaques on the Rock",
    body: "The Barbary macaques run the Upper Rock and they know it. Keep your snacks zipped away — they will help themselves. The views into two continents are unreal." },
  { city: "Paris", user: users[4], title: "Mornings in Montmartre",
    body: "Skip the midday crowds and climb to Sacré-Cœur at sunrise. The whole city unfolds below you and the cafés are just opening for the first espresso of the day." },
  { city: "Tokyo", user: users[3], title: "Getting lost in Shimokitazawa",
    body: "Vintage shops, tiny record stores, and the best curry I've had anywhere. Tokyo rewards wandering away from the obvious neighborhoods." },
  { city: "Rome", user: users[5], title: "Trastevere after dark",
    body: "Cobblestone lanes, ivy everywhere, and trattorias that don't bother with menus. Order what the table next to you is having." }
]

curated.each do |attrs|
  city = cities_by_name.fetch(attrs[:city])
  city.posts.create!(user: attrs[:user], title: attrs[:title], body: attrs[:body])
end

# ...plus a spread of generated posts so browsing always has content.
TITLE_TEMPLATES = [ "A weekend in %s", "First time in %s", "48 hours in %s",
                   "Hidden gems of %s", "Why I fell for %s", "%s on a budget" ].freeze

20.times do
  city = cities_by_name.values.sample
  user = users.sample
  title = format(TITLE_TEMPLATES.sample, city.name)
  body  = Faker::Lorem.paragraphs(number: 2).join("\n\n")
  city.posts.create!(user: user, title: title, body: body)
end

puts "Creating comments..."
Post.order("RANDOM()").limit(15).each do |post|
  rand(0..3).times do
    post.comments.create!(user: users.sample, body: Faker::Lorem.sentence(word_count: rand(6..14)))
  end
end

puts "Done. #{User.count} users, #{City.count} cities, #{Post.count} posts, #{Comment.count} comments."
