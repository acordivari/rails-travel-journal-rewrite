module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :logged_in?
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def log_in(user)
    reset_session
    session[:user_id] = user.id
    @current_user = user
  end

  def log_out
    reset_session
    @current_user = nil
  end

  # before_action guard: redirect guests to the login page.
  def require_login
    return if logged_in?

    flash[:alert] = "Please log in to continue."
    redirect_to new_session_path
  end

  # before_action guard: only administrators may proceed.
  def require_admin
    return if current_user&.admin?

    flash[:alert] = "You are not authorized to do that."
    redirect_to root_path
  end

  # Authorization helper for "owner or admin" actions.
  def authorize_owner_or_admin(record_owner)
    return if current_user && (current_user == record_owner || current_user.admin?)

    flash[:alert] = "You are not authorized to do that."
    redirect_to root_path
  end
end
