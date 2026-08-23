class ReadingChallenge < ApplicationRecord
  belongs_to :user

  validates :year, presence: true, uniqueness: {scope: :user_id},
    numericality: {only_integer: true, greater_than_or_equal_to: 2000, less_than_or_equal_to: 2200}
  validates :goal, presence: true, numericality: {only_integer: true, greater_than: 0}

  after_save :award_badges

  def books_finished_count
    @books_finished_count ||= user.readings.finished.where(finished_on: Date.new(year, 1, 1)..Date.new(year, 12, 31)).count
  end

  def progress_percent
    [(books_finished_count * 100.0 / goal).round, 100].min
  end

  def completed?
    books_finished_count >= goal
  end

  private

  def award_badges
    user.award_badges!
  end
end
