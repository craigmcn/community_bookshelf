json.genre_breakdown @genre_breakdown.map { |genre, count| {genre: genre, count: count} }
json.books_finished_by_month @books_finished_by_month.map { |month, count| {month: month, count: count} }
json.pages_read_by_month @pages_read_by_month.map { |month, pages| {month: month, pages: pages} }
