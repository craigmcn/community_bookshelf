class GoodreadsImportsController < ApplicationController
  MAX_FILE_BYTES = 5.megabytes

  def new
  end

  def create
    file = params[:file]
    return redirect_to new_goodreads_import_path, alert: "Please choose a CSV file to upload." if file.blank?
    return redirect_to new_goodreads_import_path, alert: "That file is too large (maximum is #{MAX_FILE_BYTES / 1.megabyte}MB)." if file.size > MAX_FILE_BYTES

    result = GoodreadsImport.new(current_user, file.read).call
    notice = "Imported #{result.imported_count} book(s)."
    notice += " Skipped #{result.skipped_count} row(s) already on your shelf or missing a title/author." if result.skipped_count.positive?
    redirect_to readings_path, notice: notice
  rescue CSV::MalformedCSVError
    redirect_to new_goodreads_import_path, alert: "That file doesn't look like a valid CSV export."
  end
end
