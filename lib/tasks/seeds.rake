namespace :db do
  namespace :seed do
    # The seeds promise that a re-run matches what's already there (#251), so seed again and
    # fail if any table's row count changed. Run it after db:seed or db:seed:replant.
    desc "Re-run db/seeds.rb and fail if it adds or removes any rows"
    task verify_rerun: :environment do
      connection = ActiveRecord::Base.connection
      tables = connection.tables - %w[schema_migrations ar_internal_metadata]
      count_rows = -> { tables.index_with { |t| connection.select_value("SELECT COUNT(*) FROM #{connection.quote_table_name(t)}").to_i } }

      before = count_rows.call
      Rails.application.load_seed
      changed = count_rows.call.reject { |table, count| before[table] == count }

      abort "Seed re-run changed row counts: #{changed.map { |t, c| "#{t} #{before[t]} -> #{c}" }.join(", ")}" if changed.any?
      puts "Seed re-run left all #{tables.size} tables unchanged."
    end
  end
end
