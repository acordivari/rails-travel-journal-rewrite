class HomeController < ApplicationController
  def index
    @featured_cities = City.left_joins(:posts)
                           .select("cities.*, COUNT(posts.id) AS posts_count")
                           .group("cities.id")
                           .order("posts_count DESC, cities.name ASC")
                           .limit(6)
    @recent_posts = Post.includes(:user, :city).recent.limit(4)
  end
end
