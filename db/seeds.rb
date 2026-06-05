# Roles
admin_role = Role.find_or_create_by!(name: "admin")
moderator_role = Role.find_or_create_by!(name: "moderator")
member_role = Role.find_or_create_by!(name: "member")

# Users
# Admins and moderators always have member permissions without requiring a member role assignment.
admin_user = User.find_or_create_by!(email: "admin@communitybookshelf.org") { |u| u.password = User::DEFAULT_PASSWORD }
admin_user.roles = [admin_role, moderator_role]

mod_user = User.find_or_create_by!(email: "moderator@communitybookshelf.org") { |u| u.password = User::DEFAULT_PASSWORD }
mod_user.roles = [moderator_role]

member1 = User.find_or_create_by!(email: "alice@example.com") { |u| u.password = User::DEFAULT_PASSWORD }
member1.roles = [member_role]

member2 = User.find_or_create_by!(email: "bob@example.com") { |u| u.password = User::DEFAULT_PASSWORD }
member2.roles = [member_role]

member3 = User.find_or_create_by!(email: "carol@example.com") { |u| u.password = User::DEFAULT_PASSWORD }
member3.roles = [member_role]

all_users = [admin_user, mod_user, member1, member2, member3]

# Books
books = [
  {title: "The Great Gatsby", author: "F. Scott Fitzgerald", cover_url: "https://covers.openlibrary.org/b/id/10590366-M.jpg"},
  {title: "To Kill a Mockingbird", author: "Harper Lee", cover_url: "https://covers.openlibrary.org/b/id/14351077-M.jpg"},
  {title: "1984", author: "George Orwell", cover_url: "https://covers.openlibrary.org/b/id/9267242-M.jpg"},
  {title: "Pride and Prejudice", author: "Jane Austen", cover_url: "https://covers.openlibrary.org/b/id/14348537-M.jpg"},
  {title: "The Catcher in the Rye", author: "J.D. Salinger"},
  {title: "Brave New World", author: "Aldous Huxley"},
  {title: "The Road", author: "Cormac McCarthy"}
]

books.each_with_index do |attrs, i|
  book = Book.find_or_create_by!(title: attrs[:title]) do |b|
    b.author = attrs[:author]
    b.added_by = all_users[i % all_users.size]
  end
  book.update!(cover_url: attrs[:cover_url]) if attrs[:cover_url]
end

# Readings
statuses = Reading.statuses.keys
ratings = Reading.ratings.keys

Book.find_each do |book|
  all_users.each do |user|
    next if rand < 0.4  # not every user reads every book

    status = statuses.sample
    Reading.find_or_create_by!(user: user, book: book) do |r|
      r.status = status
      r.rating = ratings.sample if status == "finished"
    end
  end
end
