require "test_helper"

class BookTest < ActiveSupport::TestCase
  test "valid with title, author, and added_by" do
    assert Book.new(title: "Test", author: "Author", added_by: users(:member)).valid?
  end

  test "invalid without title" do
    assert_not Book.new(author: "Author", added_by: users(:member)).valid?
  end

  test "invalid without author" do
    assert_not Book.new(title: "Test", added_by: users(:member)).valid?
  end

  test "valid without isbn, page_count, or published_on" do
    assert Book.new(title: "Test", author: "Author", added_by: users(:member)).valid?
  end

  test "invalid with a zero or negative page_count" do
    book = Book.new(title: "Test", author: "Author", added_by: users(:member), page_count: 0)
    assert_not book.valid?

    book.page_count = -5
    assert_not book.valid?
  end

  test "valid with a positive page_count" do
    book = Book.new(title: "Test", author: "Author", added_by: users(:member), page_count: 320)
    assert book.valid?
  end

  test "assigning tag_list creates and links tags, normalizing names" do
    book = books(:one)
    book.update!(tag_list: " Fantasy, coming-of-age , fantasy ")

    assert_equal ["coming-of-age", "fantasy"], book.tags.order(:name).pluck(:name)
  end

  test "assigning tag_list reuses existing tags instead of duplicating them" do
    book = books(:one)
    existing_count = Tag.count

    book.update!(tag_list: tags(:one).name)

    assert_equal existing_count, Tag.count
    assert_equal [tags(:one)], book.tags
  end

  test "assigning an empty tag_list clears existing tags" do
    book = books(:one) # already tagged with tags(:one) via the taggings fixture

    book.update!(tag_list: "")

    assert_empty book.tags
  end

  test "not assigning tag_list on update leaves existing tags untouched" do
    book = books(:one) # already tagged with tags(:one) via the taggings fixture

    book.update!(title: "New Title")

    assert_equal [tags(:one)], book.reload.tags
  end

  test "tag_list reader returns comma-separated tag names when not assigned" do
    book = books(:one) # already tagged with tags(:one) via the taggings fixture

    assert_equal "fantasy", book.reload.tag_list
  end

  test "clears series_position when series_id is blank" do
    book = Book.new(title: "Test", author: "Author", added_by: users(:member), series_position: 3)
    book.valid?
    assert_nil book.series_position
  end

  test "keeps series_position when a series is set" do
    book = Book.new(
      title: "Test", author: "Author", added_by: users(:member),
      series: series(:one), series_position: 3
    )
    book.valid?
    assert_equal 3, book.series_position
  end

  test "assigning mood_list and pace_list tags them under their own category" do
    book = books(:one)
    book.update!(mood_list: "dark, hopeful", pace_list: "fast-paced")

    assert_equal ["dark", "hopeful"], book.tags.mood.order(:name).pluck(:name)
    assert_equal ["fast-paced"], book.tags.pace.order(:name).pluck(:name)
  end

  test "assigning mood_list leaves existing genre tags untouched" do
    book = books(:one) # already tagged with tags(:one), a genre tag, via the taggings fixture

    book.update!(mood_list: "dark")

    assert_equal [tags(:one)], book.reload.tags.genre
    assert_equal ["dark"], book.tags.mood.pluck(:name)
  end

  test "similar_books ranks by shared tag count and excludes the book itself" do
    source = books(:one)
    source.update!(tag_list: "fantasy, epic")

    close_match = Book.create!(title: "Close Match", author: "A. Uthor", added_by: users(:member), tag_list: "fantasy, epic")
    far_match = Book.create!(title: "Far Match", author: "A. Uthor", added_by: users(:member), tag_list: "fantasy")
    no_match = Book.create!(title: "No Match", author: "A. Uthor", added_by: users(:member), tag_list: "romance")

    results = source.reload.similar_books

    assert_equal [close_match, far_match], results.to_a
    assert_not_includes results, source
    assert_not_includes results, no_match
  end

  test "similar_books returns none when the book has no tags" do
    book = books(:two)
    assert_empty book.similar_books
  end

  test "recommended_for suggests books tagged like ones the user finished or rated highly, excluding their own shelf" do
    user = users(:member)
    finished_book = books(:one)
    finished_book.update!(tag_list: "fantasy")
    Reading.where(user: user, book: finished_book).update_all(status: Reading.statuses[:finished])

    recommended = Book.create!(title: "Recommended", author: "A. Uthor", added_by: user, tag_list: "fantasy")
    already_shelved = books(:two)
    already_shelved.update!(tag_list: "fantasy")
    Reading.create!(user: user, book: already_shelved, status: :want_to_read)

    results = Book.recommended_for(user)

    assert_includes results, recommended
    assert_not_includes results, finished_book
    assert_not_includes results, already_shelved
  end

  test "recommended_for returns none for a nil user" do
    assert_empty Book.recommended_for(nil)
  end
end
