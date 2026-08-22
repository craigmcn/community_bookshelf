class ReviewLikePolicy < ApplicationPolicy
  def create? = user.present? && record.reading.is_review_public? && record.reading.review.present?
  def destroy? = record.user == user
end
