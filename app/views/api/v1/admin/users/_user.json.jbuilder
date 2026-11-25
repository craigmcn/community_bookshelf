json.extract! user, :id, :email, :created_at
json.roles user.roles.map(&:name).sort
