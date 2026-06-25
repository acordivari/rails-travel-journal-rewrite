namespace :cities do
  desc "Fetch a stock image for every city missing one (FORCE=1 to re-fetch all)"
  task backfill_images: :environment do
    force = ENV["FORCE"] == "1"
    scope = force ? City.all : City.all.reject { |c| c.image.attached? }

    if scope.empty?
      puts "All cities already have images."
      next
    end

    scope.each do |city|
      print "#{city.name}... "
      puts city.attach_stock_image!(force: force) ? "ok" : "FAILED"
    end
  end
end
