json.array!(@users) do |user|
  json.extract! user, :id, :role, :email
  json.url user_url(user, format: :json)
end
