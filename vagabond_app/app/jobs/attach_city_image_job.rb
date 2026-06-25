# Fetches a stock image for a city off the request cycle. Enqueued when a city
# is created without an uploaded image.
class AttachCityImageJob < ApplicationJob
  queue_as :default

  def perform(city)
    city.attach_stock_image!
  end
end
