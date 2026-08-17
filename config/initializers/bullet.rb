if Rails.env.local?
  Rails.application.config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true

    if Rails.env.development?
      Bullet.alert = true
      Bullet.console = true
      Bullet.rails_logger = true
      Bullet.add_footer = true
    end

    if Rails.env.test?
      Bullet.raise = true
    end

    # SeriesController#index eager-loads :books to avoid an N+1 when rendering
    # each series' book count. With only a couple of fixture rows in test,
    # Bullet's heuristic sees too few records to justify the join and flags it
    # as unused — safelisted since the eager load is genuinely needed once a
    # series has more than a handful of books.
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Series", association: :books
  end
end
