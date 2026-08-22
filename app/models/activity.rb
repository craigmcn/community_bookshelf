class Activity < ApplicationRecord
  belongs_to :user
  belongs_to :reading

  enum :action, {
    added_book: "added_book",
    started_reading: "started_reading",
    finished_reading: "finished_reading",
    reviewed: "reviewed"
  }

  validates :action, presence: true

  def description
    case action
    when "added_book" then "added #{reading.book.title} to their shelf"
    when "started_reading" then "started reading #{reading.book.title}"
    when "finished_reading" then "finished reading #{reading.book.title}"
    when "reviewed" then "reviewed #{reading.book.title}"
    end
  end
end
