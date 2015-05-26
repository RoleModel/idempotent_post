class CachedPostResponse < ActiveRecord::Base

  KEY_TTL = 86_400 # 1 Day

  attr_accessible :duplication_key, :hash_key, :response

  def self.remove_expired_keys
    where("created_at < ?", KEY_TTL.seconds.ago).destroy_all
  end
end
