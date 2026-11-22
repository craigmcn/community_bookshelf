require "test_helper"

# A newly created production DB is seeded by db:prepare, so seeds there must create the
# roles sign-up needs and nothing else: no demo accounts with a password in source (#250).
class SeedsTest < ActiveSupport::TestCase
  test "seeding in production creates the roles and no demo data" do
    counts = [User, Book, Reading, Tag, Club].index_with(&:count)

    original_env = Rails.env
    begin
      Rails.env = "production"
      assert_output(/skipping demo data/) { Rails.application.load_seed }
    ensure
      Rails.env = original_env
    end

    assert_equal %w[admin member moderator], Role.order(:name).pluck(:name)
    counts.each { |model, count| assert_equal count, model.count, "#{model} rows were seeded" }
  end
end
