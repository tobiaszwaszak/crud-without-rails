require "hanami/router"
require 'active_record'
require "JSON"
require "faker"
require "byebug"
require "dry-validation"


ActiveRecord::Base.establish_connection(
  ENV["DATABASE_URL"]
)

class Post < ActiveRecord::Base
end

class PostContract < Dry::Validation::Contract
  params do
    required(:name).filled(:string)
    required(:body).filled(:string)
  end
end

app = Hanami::Router.new do
  # GET /posts
  get "/posts", to: ->(env) { [200, {}, [Post.all.to_json]] }

  # GET /posts/1
  get "/posts/:id", to: ->(env) do
    post = Post.find(env["router.params"][:id])
    if post
      [200, {}, [post.to_json]]
    else
      [404, {}, []]
    end
  end

  # POST /posts
  post "/posts", to: ->(env) do
    params = Rack::Request.new(env).params
    begin
      contract = PostContract.new.call(params)
      raise contract.errors.to_h if contract.errors.any?

      post_entity = Post.create(contract.to_h)

      [201, {}, [post_entity.to_json]]
    rescue => error
      [422, {}, [error.to_json]]
    end
  end

  # PUT /posts/1
  put "/posts/:id", to: ->(env) do
    post = Post.find_by(id: env["router.params"][:id])
    if post.exist?
      params = Rack::Request.new(env).params
      begin
        post_entity = post.update(params)
        [200, {}, [post_entity.to_json]]
      rescue => error
        [422, {}, [error.to_json]]
      end
    else
      [404, {}, []]
    end
  end

  # DELETE /posts/1
  delete "/posts/:id", to: ->(env) do
    post = Post.find_by(id: env["router.params"][:id])
    if post.exist?
      begin
        post.command(:delete).call
        [200, {}, []]
      rescue => error
        [422, {}, [error.to_json]]
      end
    else
      [404, {}, []]
    end
  end
end

run app
