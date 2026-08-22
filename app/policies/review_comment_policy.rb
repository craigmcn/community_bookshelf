class ReviewCommentPolicy < ApplicationPolicy
  def create? = user.present? && record.reading.is_review_public? && record.reading.review.present?
  def destroy? = record.user == user || user&.moderator_or_above?
end
