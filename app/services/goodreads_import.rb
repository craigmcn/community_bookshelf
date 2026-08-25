require "csv"

# Parses a Goodreads "export library" CSV and creates Readings (and, where
# needed, catalog Books) for the given user. Matches each row to an existing
# Book by ISBN first, then by title+author, before creating a new one — the
# same "shared catalog" model the manual book-search form uses. A row is
# skipped (not overwritten) when the user already has an active Reading for
# that book, so re-uploading the same export is a no-op rather than a pile of
# duplicates — a book soft-deleted from the shelf isn't "already on it", so
# re-importing it creates a fresh Reading.
class GoodreadsImport
  Result = Struct.new(:imported_count, :skipped_count)

  SHELF_STATUS = {
    "read" => "finished",
    "currently-reading" => "reading",
    "to-read" => "want_to_read"
  }.freeze

  def initialize(user, csv_content)
    @user = user
    @csv_content = csv_content
  end

  def call
    imported = 0
    skipped = 0

    content = normalize_encoding(@csv_content)

    CSV.parse(content, headers: true, liberal_parsing: true).each do |row|
      book = find_or_create_book(row)
      if book.nil?
        skipped += 1
        next
      end

      # Default-scoped (active readings only) so a book the member soft-deleted
      # from their shelf can be re-imported — a matching soft-deleted Reading
      # doesn't count as "already on your shelf", and a fresh one is created.
      reading = Reading.find_or_initialize_by(user: user, book: book)
      unless reading.new_record?
        skipped += 1
        next
      end

      apply_row(reading, row)
      if reading.save
        imported += 1
      else
        skipped += 1
      end
    end

    Result.new(imported_count: imported, skipped_count: skipped)
  end

  private

  attr_reader :user

  # Uploaded file content typically arrives as ASCII-8BIT (binary), so a raw
  # UTF-8 BOM literal can't be compared/stripped via String methods without
  # raising Encoding::CompatibilityError. Strip the BOM at the byte level
  # first, then force UTF-8 and scrub any invalid byte sequences (rather than
  # raising) so a non-ASCII author/title doesn't crash the whole import.
  def normalize_encoding(content)
    content = content.dup.force_encoding(Encoding::BINARY)
    content = content.byteslice(3..) || +"" if content.start_with?("\xEF\xBB\xBF".b)
    content.force_encoding(Encoding::UTF_8).scrub
  end

  def find_or_create_book(row)
    title = row["Title"].to_s.strip
    author = row["Author"].to_s.strip
    return nil if title.blank? || author.blank?

    isbn = clean_isbn(row["ISBN13"].presence || row["ISBN"])

    book = Book.find_by(isbn: isbn) if isbn.present?
    book ||= Book.find_by("lower(title) = ? AND lower(author) = ?", title.downcase, author.downcase)
    return book if book

    book = Book.new(title: title, author: author, isbn: isbn, page_count: parse_page_count(row["Number of Pages"]), added_by: user)
    book.save ? book : nil
  end

  def clean_isbn(raw)
    raw.to_s.delete('="').strip.presence
  end

  def parse_page_count(raw)
    pages = raw.to_s.strip.to_i
    pages.positive? ? pages : nil
  end

  def apply_row(reading, row)
    reading.skip_activity_logging = true
    reading.status = SHELF_STATUS.fetch(row["Exclusive Shelf"].to_s.strip, "want_to_read")

    my_rating = row["My Rating"].to_s.strip.to_i
    reading.rating = my_rating if my_rating.between?(1, 5)

    reading.review = row["My Review"].presence
    reading.finished_on = parse_date(row["Date Read"])
  end

  def parse_date(raw)
    Date.parse(raw.to_s.strip)
  rescue ArgumentError, TypeError
    nil
  end
end
