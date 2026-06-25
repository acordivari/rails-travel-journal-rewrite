module PostsHelper
  # New posts are created under their city (nested route); persisted posts use
  # the shallow member route.
  def post_form_target(post)
    post.persisted? ? post : [ post.city, post ]
  end
end
