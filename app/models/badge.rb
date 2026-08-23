# Badge definitions are a fixed, hardcoded registry rather than a database
# table — there's no admin UI to manage them, and criteria are checks against
# a user's existing data (finished readings, reviews, streaks, challenges),
# not standalone records worth persisting. UserBadge stores which of these
# keys a given user has earned.
class Badge
  Definition = Struct.new(:key, :name, :description, :category, :criteria)

  BOOKS_FINISHED_TIERS = [1, 5, 10, 25, 50, 100].freeze
  REVIEWS_WRITTEN_TIERS = [1, 5, 10, 25].freeze
  STREAK_TIERS = [3, 5, 10, 25].freeze

  DEFINITIONS = [
    *BOOKS_FINISHED_TIERS.map do |n|
      Definition.new(
        key: "books_finished_#{n}",
        name: "#{n} #{(n == 1) ? "Book" : "Books"} Finished",
        description: "Finish #{n} #{(n == 1) ? "book" : "books"}.",
        category: "books_finished",
        criteria: ->(user) { user.finished_readings_count >= n }
      )
    end,
    *REVIEWS_WRITTEN_TIERS.map do |n|
      Definition.new(
        key: "reviews_written_#{n}",
        name: "#{n} #{(n == 1) ? "Review" : "Reviews"} Written",
        description: "Write #{n} #{(n == 1) ? "review" : "reviews"}.",
        category: "reviews_written",
        criteria: ->(user) { user.reviews_written_count >= n }
      )
    end,
    *STREAK_TIERS.map do |n|
      Definition.new(
        key: "streak_#{n}",
        name: "#{n}-Book Streak",
        description: "Finish #{n} books in a row without a gap of more than #{User::STREAK_GAP_DAYS} days between finishes.",
        category: "streak",
        criteria: ->(user) { user.current_streak >= n }
      )
    end,
    Definition.new(
      key: "challenge_completed",
      name: "Challenge Completed",
      description: "Reach your goal in an annual reading challenge.",
      category: "challenge",
      criteria: ->(user) { user.reading_challenges.any?(&:completed?) }
    )
  ].freeze

  def self.list
    DEFINITIONS
  end

  def self.find(key)
    DEFINITIONS.find { |definition| definition.key == key }
  end
end
