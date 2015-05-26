namespace :cached_post_response do
  task remove_expired_keys: :environment do
    CachedPostResponse.remove_expired_keys
  end
end
