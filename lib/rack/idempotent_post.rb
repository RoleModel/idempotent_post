require 'redis'
require 'digest'
require_relative '../../app/models/cached_post_response'

module Rack

  class IdempotentPost
    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) unless env['REQUEST_METHOD'] == 'POST'

      dup_check = DuplicationChecker.new(env)

      if dup_check.duplicate?
        headers, body = dup_check.response
        [409, headers, body]
      else
        status, headers, body = @app.call(env)
        dup_check.cache_response(status, headers, body)
        [status, headers, body]
      end

    end

    class DuplicationChecker
      attr_reader :token, :uri, :raw_post_data

      def initialize(env)
        @token = http_basic_username(env['HTTP_AUTHORIZATION'])
        @uri = env['PATH_INFO']
        @raw_post_data = env['rack.input'].read
      end

      def duplicate?
        cacheable_request? && redis.exists(hash_key)
      end

      def cache_response(status, headers, body)
        return unless cacheable_request?
        return unless [200, 201].include? status
        CachedPostResponse.create(hash_key: hash_key, duplication_key: duplication_key, response: [headers, body].to_json)
        redis.setex(hash_key, CachedPostResponse::KEY_TTL, true)
      end

      def response
        cached = CachedPostResponse.where(hash_key: hash_key, duplication_key: duplication_key).first
        JSON.parse(cached.response)
      end

      private

      def hash_key
        @hash_key ||= Digest::MD5.hexdigest(duplication_key)
      end

      def duplication_key
        @duplication_key ||= "#{token}|#{uri}|#{raw_post_data}".encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
      end

      def cacheable_request?
        raw_post_data.present? && uri && !ignored_uri?
      end

      def ignored_uri?
        (uri.gsub(/\.\w+/, '').split('/') & ignored_uris).size > 0
      end

      def http_basic_username(authorization_header)
        return nil unless authorization_header
        ::Base64.decode64(authorization_header.split(' ', 2).last || '').split(/:/, 2)[0]
      end

      def redis
        @redis ||= Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'], db: ENV['REDIS_DB'])
      end

      def ignored_uris
        %w(authenticate sessions bulk_jobs updates)
      end
    end
  end
end
