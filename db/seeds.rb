require "faker"
require "zlib"

# Fixed seed so every run generates the same names/emails/titles in the same
# order — otherwise `find_or_create_by!` below would treat each rerun's fresh
# random data as new rows instead of matching what's already there.
Faker::Config.random = Random.new(20_260_906)

TARGET_USER_COUNT = 110
TARGET_BOOK_COUNT = 320
CURRENT_YEAR = Date.current.year

# "Which N objects" choices below are keyed to a stable identifier (a user's
# id, a reading's id, a loop index) instead of drawing from Kernel's global
# rand/Faker's shared stream. Sequential draws drift the moment any earlier
# find_or_create_by! starts skipping an already-existing row, so structural
# picks (not simple content like description text) need their own isolated,
# reproducible source instead.
def seeded_rng(*key_parts)
  Random.new(Zlib.crc32(key_parts.join("|")))
end

# ---------------------------------------------------------------------------
# Roles + Users
# ---------------------------------------------------------------------------
puts "Seeding roles..."
admin_role = Role.find_or_create_by!(name: "admin")
moderator_role = Role.find_or_create_by!(name: "moderator")
member_role = Role.find_or_create_by!(name: "member")

def seed_user(email, name: nil)
  User.find_or_create_by!(email: email) do |u|
    u.name = name
    u.password = User::DEFAULT_PASSWORD
    u.email_confirmed_at = Time.current
    u.skip_confirmation_email = true
  end
end

puts "Seeding users..."
admin_user = seed_user("admin@communitybookshelf.org", name: "Admin Account")
admin_user.roles = [admin_role, moderator_role]

mod_user = seed_user("moderator@communitybookshelf.org", name: "Moderator Account")
mod_user.roles = [moderator_role]

fake_members = (TARGET_USER_COUNT - 2).times.map do
  name = Faker::Name.unique.name
  email = Faker::Internet.unique.email(name: name)
  seed_user(email, name: name)
end

all_users = [admin_user, mod_user] + fake_members
member_users = fake_members

# A handful of moderators drawn from the regular membership, so admin actions
# in the seed data (audit logs, role changes) have more than one mod to work with.
extra_moderators = member_users.sample(4, random: seeded_rng("extra-moderators"))
extra_moderators.each { |u| u.roles = [moderator_role, member_role] }

# ---------------------------------------------------------------------------
# Tags (genre / mood / pace) — real genre names read better than Faker output.
# ---------------------------------------------------------------------------
puts "Seeding tags..."
GENRE_NAMES = %w[fantasy science-fiction romance mystery thriller horror
  historical-fiction literary-fiction biography memoir self-help young-adult
  classic poetry graphic-novel dystopian adventure crime humor philosophy].freeze
MOOD_NAMES = %w[dark hopeful tense funny emotional whimsical bleak cozy].freeze
PACE_NAMES = %w[fast medium slow].freeze

genre_tags = GENRE_NAMES.map { |n| Tag.find_or_create_by!(name: n) { |t| t.category = "genre" } }
mood_tags = MOOD_NAMES.map { |n| Tag.find_or_create_by!(name: n) { |t| t.category = "mood" } }
pace_tags = PACE_NAMES.map { |n| Tag.find_or_create_by!(name: n) { |t| t.category = "pace" } }

# ---------------------------------------------------------------------------
# Series + Books
# ---------------------------------------------------------------------------
puts "Seeding series..."
SERIES_DATA = [
  {name: "The Wardstone Cycle", books: [
    {title: "The Wardstone Cycle: Book of Ash", author: "Elena Marchetti"},
    {title: "The Wardstone Cycle: Book of Salt", author: "Elena Marchetti"},
    {title: "The Wardstone Cycle: Book of Glass", author: "Elena Marchetti"}
  ]},
  {name: "Harbor Light Mysteries", books: [
    {title: "Harbor Light Mysteries: The Missing Tide", author: "Desmond Okafor"},
    {title: "Harbor Light Mysteries: A Quiet Drowning", author: "Desmond Okafor"},
    {title: "Harbor Light Mysteries: The Last Lighthouse", author: "Desmond Okafor"},
    {title: "Harbor Light Mysteries: Salt and Silence", author: "Desmond Okafor"}
  ]},
  {name: "Chronicles of the Drift", books: [
    {title: "Chronicles of the Drift: Solar Wake", author: "Priya Ramanathan"},
    {title: "Chronicles of the Drift: The Long Descent", author: "Priya Ramanathan"},
    {title: "Chronicles of the Drift: Ashes of Ceres", author: "Priya Ramanathan"}
  ]},
  {name: "The Willowmere Letters", books: [
    {title: "The Willowmere Letters: Spring", author: "Margaret Holt"},
    {title: "The Willowmere Letters: Autumn", author: "Margaret Holt"}
  ]}
].freeze

series_records = SERIES_DATA.map { |s| Series.find_or_create_by!(name: s[:name]) }

CLASSIC_BOOKS = [
  {title: "The Great Gatsby", author: "F. Scott Fitzgerald"},
  {title: "To Kill a Mockingbird", author: "Harper Lee"},
  {title: "1984", author: "George Orwell"},
  {title: "Pride and Prejudice", author: "Jane Austen"},
  {title: "The Catcher in the Rye", author: "J.D. Salinger"},
  {title: "Brave New World", author: "Aldous Huxley"},
  {title: "The Road", author: "Cormac McCarthy"},
  {title: "Moby-Dick", author: "Herman Melville"},
  {title: "War and Peace", author: "Leo Tolstoy"},
  {title: "Crime and Punishment", author: "Fyodor Dostoevsky"},
  {title: "Jane Eyre", author: "Charlotte Brontë"},
  {title: "Wuthering Heights", author: "Emily Brontë"},
  {title: "The Odyssey", author: "Homer"},
  {title: "Frankenstein", author: "Mary Shelley"},
  {title: "Dracula", author: "Bram Stoker"},
  {title: "The Picture of Dorian Gray", author: "Oscar Wilde"},
  {title: "Anna Karenina", author: "Leo Tolstoy"},
  {title: "The Grapes of Wrath", author: "John Steinbeck"},
  {title: "One Hundred Years of Solitude", author: "Gabriel García Márquez"},
  {title: "The Hobbit", author: "J.R.R. Tolkien"},
  {title: "The Lord of the Rings", author: "J.R.R. Tolkien"},
  {title: "Fahrenheit 451", author: "Ray Bradbury"},
  {title: "Slaughterhouse-Five", author: "Kurt Vonnegut"},
  {title: "The Bell Jar", author: "Sylvia Plath"},
  {title: "Beloved", author: "Toni Morrison"},
  {title: "Things Fall Apart", author: "Chinua Achebe"},
  {title: "The Kite Runner", author: "Khaled Hosseini"},
  {title: "Life of Pi", author: "Yann Martel"},
  {title: "The Alchemist", author: "Paulo Coelho"},
  {title: "Norwegian Wood", author: "Haruki Murakami"},
  {title: "The Handmaid's Tale", author: "Margaret Atwood"},
  {title: "Never Let Me Go", author: "Kazuo Ishiguro"},
  {title: "The Remains of the Day", author: "Kazuo Ishiguro"},
  {title: "A Clockwork Orange", author: "Anthony Burgess"},
  {title: "Slaughterhouse Five", author: "Kurt Vonnegut"},
  {title: "The Sun Also Rises", author: "Ernest Hemingway"},
  {title: "For Whom the Bell Tolls", author: "Ernest Hemingway"},
  {title: "The Old Man and the Sea", author: "Ernest Hemingway"},
  {title: "East of Eden", author: "John Steinbeck"},
  {title: "Of Mice and Men", author: "John Steinbeck"},
  {title: "Middlemarch", author: "George Eliot"},
  {title: "Great Expectations", author: "Charles Dickens"},
  {title: "A Tale of Two Cities", author: "Charles Dickens"},
  {title: "Oliver Twist", author: "Charles Dickens"},
  {title: "David Copperfield", author: "Charles Dickens"},
  {title: "Don Quixote", author: "Miguel de Cervantes"},
  {title: "The Brothers Karamazov", author: "Fyodor Dostoevsky"},
  {title: "The Idiot", author: "Fyodor Dostoevsky"},
  {title: "Lolita", author: "Vladimir Nabokov"},
  {title: "Invisible Man", author: "Ralph Ellison"},
  {title: "The Color Purple", author: "Alice Walker"},
  {title: "Beloved Country", author: "Alan Paton"},
  {title: "A Passage to India", author: "E.M. Forster"},
  {title: "Howards End", author: "E.M. Forster"},
  {title: "The Secret History", author: "Donna Tartt"},
  {title: "Gone with the Wind", author: "Margaret Mitchell"},
  {title: "Rebecca", author: "Daphne du Maurier"},
  {title: "The Name of the Rose", author: "Umberto Eco"},
  {title: "If on a winter's night a traveler", author: "Italo Calvino"},
  {title: "Cloud Atlas", author: "David Mitchell"},
  {title: "The Road to Wigan Pier", author: "George Orwell"},
  {title: "Animal Farm", author: "George Orwell"},
  {title: "The Trial", author: "Franz Kafka"},
  {title: "The Metamorphosis", author: "Franz Kafka"},
  {title: "Siddhartha", author: "Hermann Hesse"},
  {title: "Steppenwolf", author: "Hermann Hesse"},
  {title: "The Stranger", author: "Albert Camus"},
  {title: "The Plague", author: "Albert Camus"},
  {title: "Beloved Ashes", author: "Amara Whitfield"},
  {title: "The Joy Luck Club", author: "Amy Tan"},
  {title: "Beloved Enemy", author: "Cassandra Pryce"},
  {title: "Dune", author: "Frank Herbert"},
  {title: "Foundation", author: "Isaac Asimov"},
  {title: "Neuromancer", author: "William Gibson"},
  {title: "Snow Crash", author: "Neal Stephenson"},
  {title: "The Left Hand of Darkness", author: "Ursula K. Le Guin"},
  {title: "A Wizard of Earthsea", author: "Ursula K. Le Guin"},
  {title: "The Dispossessed", author: "Ursula K. Le Guin"},
  {title: "American Gods", author: "Neil Gaiman"},
  {title: "Good Omens", author: "Neil Gaiman"},
  {title: "The Night Circus", author: "Erin Morgenstern"},
  {title: "Circe", author: "Madeline Miller"},
  {title: "The Song of Achilles", author: "Madeline Miller"},
  {title: "Where the Crawdads Sing", author: "Delia Owens"},
  {title: "Educated", author: "Tara Westover"},
  {title: "Sapiens", author: "Yuval Noah Harari"},
  {title: "The Immortal Life of Henrietta Lacks", author: "Rebecca Skloot"}
].freeze

puts "Seeding books..."

# Built as plain data first, entirely independent of what's already in the
# DB — a book that already exists still needs its Faker draws consumed here,
# or the next iteration's title/author pull drifts out of sync with what an
# earlier run produced, and every subsequent random pick in the file drifts
# with it (this is what made the very first version of this script produce
# roughly double the rows on a second run).
book_specs = CLASSIC_BOOKS.map { |b| b.merge(series: nil, series_position: nil) }

SERIES_DATA.each_with_index do |series_def, i|
  series = series_records[i]
  series_def[:books].each_with_index do |attrs, position|
    book_specs << attrs.merge(series: series, series_position: position + 1)
  end
end

# Faker's book dataset repeats titles across draws, so specs are keyed on the
# (title, author) pair rather than title alone to avoid accidental merges.
seen_pairs = book_specs.map { |b| [b[:title], b[:author]] }.to_set
while book_specs.size < TARGET_BOOK_COUNT
  title = Faker::Book.title
  author = Faker::Book.author
  next unless seen_pairs.add?([title, author])

  book_specs << {title: title, author: author, series: nil, series_position: nil}
end

book_specs.each do |spec|
  spec[:page_count] = rand(120..820)
  spec[:published_on] = Faker::Date.between(from: "1850-01-01", to: Date.current)
  spec[:isbn] = Faker::Code.isbn
  spec[:description] = Faker::Lorem.paragraph(sentence_count: 4)
  spec[:subjects] = Array.new(rand(1..4)) { Faker::Book.genre }.uniq
  spec[:tag_list] = genre_tags.sample(rand(1..3)).map(&:name).join(", ")
  spec[:mood_list] = mood_tags.sample(rand(0..2)).map(&:name).join(", ")
  spec[:pace_list] = pace_tags.sample(1).map(&:name).join(", ")
end

books = book_specs.map do |spec|
  Book.find_or_create_by!(title: spec[:title], author: spec[:author]) do |b|
    b.added_by = all_users.sample
    b.series = spec[:series]
    b.series_position = spec[:series_position]
    b.page_count = spec[:page_count]
    b.published_on = spec[:published_on]
    b.isbn = spec[:isbn]
    b.description = spec[:description]
    b.subjects = spec[:subjects]
    b.tag_list = spec[:tag_list]
    b.mood_list = spec[:mood_list]
    b.pace_list = spec[:pace_list]
  end
end

# ---------------------------------------------------------------------------
# Readings (+ the Activity/Badge side effects Reading's callbacks already handle)
# ---------------------------------------------------------------------------
puts "Seeding readings..."
statuses = Reading.statuses.keys
ratings = Reading.ratings.keys
formats = Reading.formats.keys
soft_deleted_readings = []

all_users.each do |user|
  reading_rng = seeded_rng("readings", user.id)
  sample_books = books.sample(reading_rng.rand(10..45), random: reading_rng)

  sample_books.each do |book|
    reading = Reading.find_or_create_by!(user: user, book: book) do |r|
      r.status = "want_to_read"
    end
    next unless reading.previously_new_record?

    final_status = statuses.sample
    next if final_status == "want_to_read"

    attrs = {status: final_status, format: formats.sample}

    if final_status == "finished"
      started = Faker::Date.between(from: 2.years.ago, to: 30.days.ago)
      attrs[:started_on] = started
      attrs[:finished_on] = Faker::Date.between(from: started, to: Date.current)
      attrs[:progress_percent] = 100
      attrs[:rating] = ratings.sample
      if rand < 0.5
        attrs[:review] = Faker::Lorem.paragraph(sentence_count: rand(2..6))
        attrs[:is_review_public] = rand < 0.85
      end
    elsif final_status == "reading"
      attrs[:started_on] = Faker::Date.between(from: 60.days.ago, to: Date.current)
      attrs[:progress_percent] = rand(5..95)
    elsif final_status == "dnf"
      attrs[:started_on] = Faker::Date.between(from: 1.year.ago, to: 30.days.ago)
      attrs[:progress_percent] = rand(5..80)
    end

    reading.update!(attrs)
    soft_deleted_readings << reading if rand < 0.02
  end
end

# A rare few soft-deleted readings, so the default scope and AuditLog's
# destroy_reading action (below) have something real to reflect.
soft_deleted_readings.each { |r| r.soft_delete unless r.deleted? }

# ---------------------------------------------------------------------------
# Shelves + Shelf Books
# ---------------------------------------------------------------------------
puts "Seeding shelves..."
SHELF_NAMES = ["Favorites", "#{CURRENT_YEAR} TBR", "Currently Reading", "DNF Pile", "Comfort Rereads"].freeze

all_users.each do |user|
  shelf_rng = seeded_rng("shelves", user.id)
  next if shelf_rng.rand >= 0.7

  SHELF_NAMES.sample(shelf_rng.rand(1..3), random: shelf_rng).each do |name|
    shelf = Shelf.find_or_create_by!(user: user, name: name)
    shelf_book_rng = seeded_rng("shelf-books", shelf.id)
    books.sample(shelf_book_rng.rand(3..15), random: shelf_book_rng).each do |book|
      ShelfBook.find_or_create_by!(shelf: shelf, book: book)
    end
  end
end

# ---------------------------------------------------------------------------
# Follows (fires Follow#notify_followed_user -> Notification)
# ---------------------------------------------------------------------------
puts "Seeding follows..."
all_users.each do |user|
  follow_rng = seeded_rng("follows", user.id)
  (all_users - [user]).sample(follow_rng.rand(3..12), random: follow_rng).each do |target|
    Follow.find_or_create_by!(follower: user, followed: target)
  end
end

# ---------------------------------------------------------------------------
# Review likes + comments (comments fire ReviewComment#notify_reading_owner)
# ---------------------------------------------------------------------------
puts "Seeding review likes and comments..."
public_reviews = Reading.where.not(review: [nil, ""]).where(is_review_public: true)

public_reviews.find_each do |reading|
  engagement_rng = seeded_rng("review-engagement", reading.id)
  other_users = all_users.reject { |u| u.id == reading.user_id }

  other_users.sample(engagement_rng.rand(0..8), random: engagement_rng).each do |liker|
    ReviewLike.find_or_create_by!(user: liker, reading: reading)
  end

  next unless engagement_rng.rand < 0.4

  other_users.sample(engagement_rng.rand(1..3), random: engagement_rng).each do |commenter|
    next if ReviewComment.exists?(user: commenter, reading: reading)

    ReviewComment.create!(user: commenter, reading: reading, body: Faker::Lorem.sentence(word_count: rand(6..20)))
  end
end

# ---------------------------------------------------------------------------
# Buddy reads + messages
# ---------------------------------------------------------------------------
puts "Seeding buddy reads..."
buddy_statuses = BuddyRead.statuses.keys

15.times do |i|
  buddy_rng = seeded_rng("buddy-read", i)
  initiator, partner = all_users.sample(2, random: buddy_rng)
  book = books.sample(random: buddy_rng)
  status = buddy_statuses.sample(random: buddy_rng)
  next if BuddyRead.exists?(initiator: initiator, partner: partner, book: book)

  buddy_read = BuddyRead.create!(initiator: initiator, partner: partner, book: book, status: status)
  next unless %w[accepted completed].include?(status)

  participants = [initiator, partner]
  rand(2..6).times { |n| buddy_read.messages.create!(user: participants[n % 2], body: Faker::Lorem.sentence(word_count: rand(5..15))) }
end

# ---------------------------------------------------------------------------
# Clubs + memberships + posts (post creation fires ClubPost#notify_other_members)
# ---------------------------------------------------------------------------
puts "Seeding clubs..."
CLUB_NAME_TEMPLATES = ["%s Book Club", "The %s Readers", "%s Discussion Group"].freeze
CLUB_GENRE_LABELS = ["Fantasy", "Science Fiction", "Romance", "Mystery", "Thriller",
  "Historical Fiction", "Horror", "Classic Literature", "Poetry", "Memoir"].freeze

8.times do |i|
  club_rng = seeded_rng("club", i)
  book = books.sample(random: club_rng)
  creator = all_users.sample(random: club_rng)
  name = format(CLUB_NAME_TEMPLATES.sample(random: club_rng), CLUB_GENRE_LABELS.sample(random: club_rng))
  next if Club.exists?(name: name)

  club = Club.create!(name: name, description: Faker::Lorem.paragraph(sentence_count: 3), book: book, created_by: creator)

  member_rng = seeded_rng("club-members", club.id)
  (all_users - [creator]).sample(member_rng.rand(5..20), random: member_rng).each do |member|
    ClubMembership.find_or_create_by!(club: club, user: member)
  end

  post_rng = seeded_rng("club-posts", club.id)
  club.members.sample(post_rng.rand(2..6), random: post_rng).each do
    author = club.members.sample(random: post_rng)
    ClubPost.create!(club: club, user: author, body: Faker::Lorem.paragraph(sentence_count: rand(1..5)), spoiler: rand < 0.2)
  end
end

# ---------------------------------------------------------------------------
# Reading challenges
# ---------------------------------------------------------------------------
puts "Seeding reading challenges..."
all_users.each do |user|
  challenge_rng = seeded_rng("challenge", user.id)
  next if challenge_rng.rand >= 0.6

  ReadingChallenge.find_or_create_by!(user: user, year: CURRENT_YEAR) do |c|
    c.goal = challenge_rng.rand(12..80)
  end
end

# ---------------------------------------------------------------------------
# Favorite genres
# ---------------------------------------------------------------------------
puts "Seeding favorite genres..."
all_users.each do |user|
  favorite_genre_rng = seeded_rng("favorite-genres", user.id)
  next if favorite_genre_rng.rand >= 0.7
  next if user.favorite_genre_tags.any?

  user.update!(favorite_genre_list: genre_tags.sample(favorite_genre_rng.rand(2..4), random: favorite_genre_rng).map(&:name).join(", "))
end

# ---------------------------------------------------------------------------
# User badges — Reading/ReadingChallenge already call award_badges! on save;
# this sweep just catches anyone whose qualifying data landed after their last save.
# ---------------------------------------------------------------------------
puts "Awarding badges..."
User.find_each(&:award_badges!)

# ---------------------------------------------------------------------------
# Notifications — created by the Follow/ReviewComment/ClubPost callbacks
# above. Mark a deterministic subset read so the bell dropdown has variety.
# ---------------------------------------------------------------------------
puts "Marking some notifications read..."
Notification.where(read_at: nil).where("id % 3 != 0").find_each do |notification|
  notification.update_column(:read_at, notification.created_at + rand(1..48).hours)
end

# ---------------------------------------------------------------------------
# Audit logs — plausible moderator/admin history, tied to real records.
# ---------------------------------------------------------------------------
puts "Seeding audit logs..."
moderators_and_admins = all_users.select(&:moderator_or_above?)

member_users.sample(12, random: seeded_rng("audit-log-targets")).each do |target_user|
  audit_rng = seeded_rng("audit-log-actor", target_user.id)
  actor = moderators_and_admins.sample(random: audit_rng)
  next if AuditLog.exists?(actor: actor, action: "update_roles", subject: target_user)

  from_roles = target_user.roles.pluck(:name)
  to_roles = ([member_role.name] + ((audit_rng.rand < 0.3) ? [moderator_role.name] : [])).uniq
  AuditLog.create!(actor: actor, action: "update_roles", subject: target_user, details: {from: from_roles, to: to_roles})
end

soft_deleted_readings.select(&:deleted?).each do |reading|
  actor = moderators_and_admins.sample(random: seeded_rng("audit-log-reading-actor", reading.id))
  next if AuditLog.exists?(actor: actor, action: "destroy_reading", subject: reading)

  AuditLog.create!(
    actor: actor, action: "destroy_reading", subject: reading,
    details: {owner_email: reading.user.email, book_title: reading.book.title}
  )
end

puts "Done."
