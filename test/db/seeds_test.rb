require "test_helper"

# A newly created production DB is seeded by db:prepare, so seeds there must create the
# roles sign-up needs and nothing else: no demo accounts with a password in source (#250).
class SeedsTest < ActiveSupport::TestCase
  %w[production staging].each do |env|
    test "seeding in #{env} creates the roles and no demo data" do
      # The fixtures already hold every role, so clear them to prove seeding creates them.
      RoleAssignment.delete_all
      Role.delete_all
      counts = [User, Book, Reading, Tag, Club].index_with(&:count)

      seed_as(env)

      assert_equal %w[admin member moderator], Role.order(:name).pluck(:name)
      counts.each { |model, count| assert_equal count, model.count, "#{model} rows were seeded" }
    end
  end

  private

  def seed_as(env)
    original_env = Rails.env
    Rails.env = env
    assert_output(/#{env}: skipping demo data/) { Rails.application.load_seed }
  ensure
    Rails.env = original_env
  end
end
