class WheelSize < ActiveRecord::Base
  attr_accessible :name, :priority, :description, :iso_bsd
  validates_presence_of :name, :priority, :description, :iso_bsd
  validates_uniqueness_of :description, :iso_bsd
  has_many :bikes

  default_scope order(:iso_bsd)
  scope :commonness, order("priority ASC, iso_bsd DESC")

  def select_value
    "[#{iso_bsd}] #{description}"
  end

end
