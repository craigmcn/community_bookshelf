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
  end
end
