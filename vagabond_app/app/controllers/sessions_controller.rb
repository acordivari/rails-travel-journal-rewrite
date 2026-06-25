class SessionsController < ApplicationController
  def new
    redirect_to root_path if logged_in?
  end

  def create
    user = User.authenticate_by(email: params[:email].to_s.strip.downcase,
                                password: params[:password])
    if user
      log_in(user)
      flash[:notice] = "Welcome back, #{user.name}!"
      redirect_to user_path(user)
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    log_out
    flash[:notice] = "You have been logged out."
    redirect_to root_path
  end
end
