class Ride < ActiveRecord::Base
  belongs_to :driver, class_name: 'User'
  has_many :passengers, class_name: 'User', through: :rides_passengers
  has_many :rides_passengers

  validates :start_city,       presence: true
  validates :destination_city, presence: true
  validates :seats,            presence: true
  validates :start_date,       presence: true
  validates :driver_id,        presence: true
  validates :price,            presence: true, format: { with: /\A\d+(?:\.\d{0,2})?\z/ }, numericality: { greater_than: 0 }

  scope :other_users_rides, ->(current_user) { where.not(driver_id: current_user.id) if current_user.present? }

  scope :completed, -> { where("start_date <= ?", Time.now) }
  scope :upcoming, -> { where("start_date > ?", Time.now) }

  scope :start_city, ->(query) { where("start_city ilike ?", "%#{query}%") }
  scope :destination_city, ->(query) { where("destination_city ilike ?", "%#{query}%") }

  scope :with_accepted_requests, -> { where(rides_passengers: { status: RidesPassenger.statuses[:accepted]}) }

  def free_rides_count
    seats - rides_passengers.where(status: RidesPassenger.statuses[:accepted]).count
  end

  def author?(current_user)
    current_user.present? ? current_user == driver : false
  end

  def free_rides?
    self.free_rides_count > 0
  end

  def requested?(current_user)
    rides_passengers.find_by(passenger_id: current_user.id).present? if current_user.present?
  end

  def accepted_requests
    rides_passengers.where(status: RidesPassenger.statuses[:accepted]).count
  end

  def rides_passengers_status(current_user)
    rides_passengers.find_by(passenger_id: current_user.id).status if current_user.present?
  end
end
