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

    # ShelvesController#index eager-loads :shelf_books to avoid an N+1 when
    # rendering each shelf's book count. Same low-fixture-count false positive
    # as the Series safelist above.
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Shelf", association: :shelf_books

    # NotificationsController#index eager-loads :notifiable to render each
    # notification's message, but that method only dereferences notifiable
    # for review_comment/club_post types, not new_follower — a page of
    # notifications that happens to be all new-follower rows trips Bullet's
    # unused-eager-load heuristic even though the include is needed whenever
    # the other types are present.
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Notification", association: :notifiable
  end
end
