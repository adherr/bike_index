class UsersController < ApplicationController
  before_filter :authenticate_user!, only: [:edit]
  
  def new
    @user = User.new
    if current_user.present?
      flash[:notice] = "You're already signed in, silly! You can log out by clicking on 'Your Account' in the upper right corner"
      redirect_to user_home_url and return
    end
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      CreateUserJobs.new(user: @user).do_jobs
      if @user.confirmed
        session[:user_id] = @user.id
        session[:last_seen] = Time.now
        redirect_to user_home_url, notice: "Logged in!" and return
      end
    else
      render action: :new
    end
  end

  def confirm
    begin
      @user = User.find(params[:id])
      if @user.confirmed?
        redirect_to new_session_url, notice: "Your user account is already confirmed. Please log in"
      else
        if @user.confirm(params[:code])
          session[:user_id] = @user.id
          redirect_to user_home_url
        else
          render :confirm_error_bad_token
        end
      end
    rescue ActiveRecord::RecordNotFound
      render :confirm_error_404
    end
  end

  def request_password_reset
  end

  def update_password
    @user = current_user
  end

  def password_reset
    if params[:token].present?
      @user = User.find_by_password_reset_token(params[:token])
      if @user.present?
        session[:user_id] = @user.id
        flash[:notice] = "You've been logged in. Please reset your password"
        render action: :update_password
      else
        flash[:error] = "We're sorry, but that link is no longer valid."
        render action: :request_password_reset
      end
    elsif params[:email].present?
      @user = User.fuzzy_email_find(params[:email])
      if @user.present?
        @user.send_password_reset_email
      else
        flash[:error] = "Sorry, that email address isn't in our system."
        render action: :request_password_reset
      end
    else
      redirect_to '/users/request_password_reset'
    end
  end

  def show
    user = User.find_by_username(params[:id])
    unless user 
      raise ActionController::RoutingError.new('Not Found')
    end
    @owner = user
    @user = user.decorate
    if user == current_user
      # Render the site
    else
      unless @user.show_bikes
        redirect_to user_home_url, notice: "Sorry, that user isn't sharing their bikes" and return
      end
    end
    bikes = Bike.where('id in (?)', user.bikes).includes(:cycle_type, :manufacturer, :primary_frame_color, :secondary_frame_color, :tertiary_frame_color)
    @bikes = BikeDecorator.decorate_collection(bikes)
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    # respond_to do |format|
    if @user.update_attributes(params[:user])
      if params[:user][:terms_of_service].present?
        if params[:user][:terms_of_service] == '1'
          @user.terms_of_service = true
          @user.save
          redirect_to user_home_url, notice: "Thanks! Now you can use the Bike Index"
        else
          redirect_to accept_vendor_terms_url, notice: "You have to accept the Terms of Service if you would like to use Bike Index"
        end
      elsif params[:user][:vendor_terms_of_service].present?
        if params[:user][:vendor_terms_of_service] == '1'
          @user.accept_vendor_terms_of_service
          if @user.memberships.any?
            flash[:notice] = "Thanks! Now you can use Bike Index as #{@user.memberships.first.organization.name}"
          else
            flash[:notice] = "Thanks for accepting the terms of service!"
          end
          redirect_to user_home_url
          # TODO: Redirect to the correct page, somehow this breaks things right now though.
          # redirect_to organization_home
        else
          redirect_to accept_vendor_terms_url, notice: "You have to accept the Terms of Service if you would like to use Bike Index as through the organization"
        end
      else
        redirect_to my_account_url, notice: 'Your information was successfully updated.'
      end
    else
      render action: :edit
    end
  end

  def accept_terms
    if current_user.present?
      @user = current_user
    else
      redirect_to terms_url
    end
  end

  def accept_vendor_terms
    if current_user.present?
      @user = current_user
    else
      redirect_to vendor_terms_url
    end
  end

end
