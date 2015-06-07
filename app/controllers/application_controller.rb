class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  helper_method :current_user, :current_action

  before_action :authorize
  after_action :cache_redirected_action

  private
  def current_user
    User.find_by_id(session[:current_user_id])
  end

  def login_user(user)
    session[:current_user_id] = user.id
  end

  def current_action
    [current_user.try(:role) || 'anonymous', controller_name, action_name]
  end

  def authorize
    seq = Rails.configuration.privileges[current_action]
    if seq.last == :mismatch
      flash.now[:error] = "You're not authorized to do this action."
      render "layouts/401", status: :unauthorized
    end
  end

  def cache_redirected_action
    session[:redirected_action] = if response.status == 302
                                    current_action
                                  end
  end
end
