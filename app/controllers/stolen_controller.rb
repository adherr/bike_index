class StolenController < ApplicationController
  # caches_page :index
  layout 'sbr'
  
  def index
    # stolen_bikes = StolenRecord.where(current: true).order(:date_stolen).limit(6).pluck(:bike_id)
    # stolen_bikes = StolenRecord.where(approved: true).order('date_stolen DESC').limit(6).pluck(:bike_id)
    @feedback = Feedback.new
    # render action: 'index', layout: 'sbr'

  end

  def current_tsv
    redirect_to 'https://s3.amazonaws.com/bikeindex/uploads/current_stolen_bikes.tsv'
  end

  def links
    @title = ' links'
  end

  def about
    @title = ' FAQ'
  end

  def tech
    @title = ' - Technology for fighting bike theft'
  end

  def identidots
    @title = ' - Identidots'
  end

  def rfid_tags_for_the_win
    @title = ' - Open Source Bike Recovery On The Cheap'
  end

  def howworks
    @title = ' - how it works'
  end

  def merging
    @title = ' - stolen bike registration that works'
    stolen_bikes = StolenRecord.where(approved: true).order('date_stolen DESC').limit(6).pluck(:bike_id)
    @stolen_bikes = Bike.where('id in (?)', stolen_bikes).includes(:stolen_records).decorate
    @feedback = Feedback.new
    render action: 'index'
  end

  def multi_serial_search
    render layout: 'multi_serial'
  end

end