json.user do
  json.extract! @user, :id, :email, :name, :display_name
  json.roles @user.roles.map(&:name)
end
json.csrf_token @csrf_token
