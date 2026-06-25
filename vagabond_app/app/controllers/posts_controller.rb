class PostsController < ApplicationController
  before_action :require_login, only: %i[new create edit update destroy]
  before_action :set_city, only: %i[index new create]
  before_action :set_post, only: %i[show edit update destroy]
  before_action -> { authorize_owner_or_admin(@post.user) }, only: %i[edit update destroy]

  def index
    @posts = @city.posts.includes(:user).recent
  end

  def show
    @comments = @post.comments.includes(:user).chronological
    @comment = @post.comments.build
  end

  def new
    @post = @city.posts.build
  end

  def create
    @post = @city.posts.build(post_params)
    @post.user = current_user
    if @post.save
      flash[:notice] = "Post published."
      redirect_to post_path(@post)
    else
      flash.now[:alert] = @post.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @post.update(post_params)
      flash[:notice] = "Post updated."
      redirect_to post_path(@post)
    else
      flash.now[:alert] = @post.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    city = @post.city
    @post.destroy
    flash[:notice] = "Post deleted."
    redirect_to city_path(city)
  end

  private

  def set_city
    @city = City.find(params[:city_id])
  end

  def set_post
    @post = Post.includes(:user, :city).find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body, :photo)
  end
end
