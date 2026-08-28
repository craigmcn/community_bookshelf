class AuditLog < ApplicationRecord
  belongs_to :actor, class_name: "User"
  belongs_to :subject, polymorphic: true

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
