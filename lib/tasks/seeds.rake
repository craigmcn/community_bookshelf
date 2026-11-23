namespace :db do
  namespace :seed do
    # The seeds promise that a re-run matches what's already there (#251), so seed again and fail
    # if any table changed. MAX(id) catches a delete plus a re-create, which leaves the count alone.
    desc "Re-run db/seeds.rb and fail if it adds or removes any rows"
    task verify_rerun: :environment do
      connection = ActiveRecord::Base.connection
      tables = connection.tables - %w[schema_migrations ar_internal_metadata]
      snapshot = lambda do
        tables.index_with do |table|
          key = connection.primary_key(table)
          max = key ? ", MAX(#{connection.quote_column_name(key)})" : ""
          connection.select_rows("SELECT COUNT(*)#{max} FROM #{connection.quote_table_name(table)}").first.join("/")
        end
      end

      before = snapshot.call
      Rails.application.load_seed
      changed = snapshot.call.reject { |table, state| before[table] == state }

      abort "Seed re-run changed tables (count/max id): #{changed.map { |t, s| "#{t} #{before[t]} -> #{s}" }.join(", ")}" if changed.any?
      puts "Seed re-run left all #{tables.size} tables unchanged."
    end
  end
end
