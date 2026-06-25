class UsersController < ApplicationController
  before_action :require_login, only: %i[edit update destroy]
  before_action :set_user, only: %i[show edit update destroy]
  before_action -> { authorize_owner_or_admin(@user) }, only: %i[edit update destroy]

  def index
    @users = User.order(:name)
  end

  def show
    @posts = @user.posts.includes(:city).recent
  end

  def new
    redirect_to(root_path) and return if logged_in?

    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in(@user)
      flash[:notice] = "Welcome to Vagabond, #{@user.name}!"
      redirect_to user_path(@user)
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @user.update(user_params)
      flash[:notice] = "Profile updated."
      redirect_to user_path(@user)
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    log_out if @user == current_user
    flash[:notice] = "Account removed."
    redirect_to root_path
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    permitted = params.require(:user).permit(:name, :current_city, :email, :password, :avatar)
    # Password is optional on update; drop it when blank so the digest is preserved.
    permitted.delete(:password) if action_name == "update" && permitted[:password].blank?
    permitted
  end
end
