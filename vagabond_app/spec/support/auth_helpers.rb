module AuthHelpers
  # Logs in via the real session endpoint so the controller session cookie is set.
  def sign_in(user, password: "password")
    post session_path, params: { email: user.email, password: password }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
