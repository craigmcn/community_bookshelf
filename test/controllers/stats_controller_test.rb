require "test_helper"

class StatsControllerTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    get stats_url
    assert_redirected_to sign_in_path
  end

  test "member can view their own stats with no finished readings" do
    sign_in_as users(:member)
    get stats_url
    assert_response :success
    assert_select "p", text: /Finish a book with a genre tag/
    assert_select "p", text: /Finish a book to start tracking your pace/
    assert_select "p", text: /Finish a book with a page count/
  end

  test "member's stats reflect their own finished, tagged, paged books" do
    tag = tags(:one)
    book = books(:one)
    book.update!(page_count: 300)
    Reading.create!(user: users(:member), book: book, status: :finished, finished_on: Date.current)

    sign_in_as users(:member)
    get stats_url

    assert_response :success
    assert_select "p", text: /Finish a book with a genre tag/, count: 0
    assert_select "p", text: /Finish a book to start tracking your pace/, count: 0
    assert_select "p", text: /Finish a book with a page count/, count: 0
    assert_includes @response.body, tag.name
  end
end
