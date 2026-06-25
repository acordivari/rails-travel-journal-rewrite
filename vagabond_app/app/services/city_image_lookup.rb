require "net/http"
require "json"
require "stringio"

# Finds a stock photo for a city by name, with no API key required.
#
# Strategy (first hit wins):
#   1. Wikipedia REST "page summary" — the city's lead photo (e.g. London's
#      skyline). Flags, seals, coats of arms, maps and SVG icons are rejected so
#      we don't end up attaching, say, the flag of Gibraltar instead of a view.
#   2. Openverse — search across openly-licensed photos (Flickr, etc.) for the
#      city name and take the top result. Returns genuine travel photography.
#   3. Picsum — a deterministic, always-available fallback keyed on the city
#      name, so we never end up with a broken image.
#
# Returns a CityImageLookup::Result (io / filename / content_type / source_url),
# or nil if everything fails.
class CityImageLookup
  USER_AGENT   = "VagabondApp/1.0 (https://github.com/acordivari/rails-travel-journal-rewrite)".freeze
  WIKI_SUMMARY = "https://en.wikipedia.org/api/rest_v1/page/summary/%s".freeze
  OPENVERSE    = "https://api.openverse.org/v1/images/?q=%s&page_size=1&mature=false".freeze
  PICSUM       = "https://picsum.photos/seed/%s/1200/800".freeze
  TIMEOUT      = 8
  MAX_BYTES    = 15.megabytes

  # Wikipedia lead images we don't want as a city "photo".
  NON_PHOTO = /flag|seal|coat[_ ]of[_ ]arms|emblem|crest|logo|map|locator|\.svg\z/i

  Result = Struct.new(:io, :filename, :content_type, :source_url, keyword_init: true)

  def self.call(name) = new(name).call

  def initialize(name)
    @name = name.to_s.strip
  end

  def call
    return if @name.blank?

    url = wikipedia_image_url || openverse_image_url || picsum_url
    url && download(url)
  rescue => e
    Rails.logger.warn("[CityImageLookup] #{@name}: #{e.class}: #{e.message}")
    nil
  end

  private

  def wikipedia_image_url
    title = @name.tr(" ", "_")
    body  = http_get(URI(format(WIKI_SUMMARY, url_escape(title))))
    json  = JSON.parse(body)
    url   = json.dig("originalimage", "source").presence || json.dig("thumbnail", "source").presence
    url unless url.nil? || url.match?(NON_PHOTO)
  rescue => e
    Rails.logger.info("[CityImageLookup] Wikipedia miss for #{@name}: #{e.message}")
    nil
  end

  def openverse_image_url
    body = http_get(URI(format(OPENVERSE, url_escape(@name))))
    JSON.parse(body).dig("results", 0, "url").presence
  rescue => e
    Rails.logger.info("[CityImageLookup] Openverse miss for #{@name}: #{e.message}")
    nil
  end

  def picsum_url
    format(PICSUM, url_escape(@name.parameterize.presence || "city"))
  end

  def download(url)
    uri  = URI(url)
    data = http_get(uri, accept: "image/*")
    raise "empty response" if data.blank?
    raise "image too large" if data.bytesize > MAX_BYTES

    io           = StringIO.new(data)
    content_type = Marcel::MimeType.for(io, name: File.basename(uri.path))
    # Guard against error pages / non-raster payloads being attached as "images".
    raise "not a raster image: #{content_type}" unless content_type.start_with?("image/")
    raise "vector image" if content_type.include?("svg")

    ext = content_type.split("/").last.sub("jpeg", "jpg")

    Result.new(
      io: io,
      filename: "#{@name.parameterize}.#{ext}",
      content_type: content_type,
      source_url: url
    )
  end

  def http_get(uri, accept: "application/json", redirects: 5)
    raise "too many redirects" if redirects.negative?

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                               open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      http.get(uri.request_uri, "User-Agent" => USER_AGENT, "Accept" => accept)
    end

    case response
    when Net::HTTPSuccess      then response.body
    when Net::HTTPRedirection  then http_get(URI.join(uri, response["location"]), accept:, redirects: redirects - 1)
    else raise "HTTP #{response.code} for #{uri}"
    end
  end

  def url_escape(string)
    ERB::Util.url_encode(string)
  end
end
