json.id club_post.id
json.club_id club_post.club_id
json.user_id club_post.user_id
json.spoiler club_post.spoiler
json.created_at club_post.created_at
json.hidden !visible
json.body visible ? club_post.body : nil
