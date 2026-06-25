class CitiesController < ApplicationController
  before_action :require_login, only: %i[new create destroy]
  before_action :require_admin, only: %i[new create destroy]
  before_action :set_city, only: %i[show destroy]

  def index
    @cities = City.left_joins(:posts)
                  .select("cities.*, COUNT(posts.id) AS posts_count")
                  .group("cities.id")
                  .order(:name)
  end

  def show
    @posts = @city.posts.includes(:user).recent
    @post = @city.posts.build
  end

  def new
    @city = City.new
  end

  def create
    @city = City.new(city_params)
    if @city.save
      # No upload? Fetch a stock photo for the city by name in the background.
      AttachCityImageJob.perform_later(@city) unless @city.image.attached?
      flash[:notice] = "#{@city.name} added."
      redirect_to city_path(@city)
    else
      flash.now[:alert] = @city.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @city.destroy
    flash[:notice] = "#{@city.name} removed."
    redirect_to cities_path
  end

  private

  def set_city
    @city = City.find(params[:id])
  end

  def city_params
    params.require(:city).permit(:name, :image)
  end
end
