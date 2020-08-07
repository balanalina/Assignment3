class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user &.authenticate(params[:session][:password])
      reset_session
      log_in user
      redirect_to user
    else
      flash.now[:danger] = 'Invalid email/password combination!'
      render 'new'
    end
  end

  def new
  end

  def destroy
    log_out
    redirect_to root_url
  end
end
