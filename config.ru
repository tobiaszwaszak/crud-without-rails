require "hanami/router"
require "sequel"
require "JSON"
require "faker"
require "byebug"
require "dry-validation"

DB = Sequel.sqlite

DB.create_table :posts do
  primary_key :id
  String :name
  Text :body
end

33.times do
  DB[:posts].insert(name: Faker::FunnyName.four_word_name, body: Faker::Books::Lovecraft.paragraph)
end

class PostContract < Dry::Validation::Contract
  params do
    required(:name).filled(:string)
    required(:body).filled(:string)
  end
end

app = Hanami::Router.new do
  # GET /posts
  get "/posts", to: ->(env) { [200, {}, [DB[:posts].all.to_json]] }

  # GET /posts/1
  get "/posts/:id", to: ->(env) do
    post = DB[:posts].first(id: env["router.params"][:id])
    if post
      [200, {}, [DB[:posts].first(id: env["router.params"][:id]).to_json]]
    else
      [404, {}, []]
    end
  end

  # POST /posts
  post "/posts", to: ->(env) do
    params = Rack::Request.new(env).params
    begin
      contract = PostContract.new.call(params)
      params = contract.to_h
      raise contract.errors.to_h if contract.errors.any?

      post_entity = DB[:posts].insert(params)
      [201, {}, [DB[:posts].first(id: post_entity).to_json]]
    rescue => error
      [422, {}, [error.to_json]]
    end
  end

  # PUT /posts/1
  put "/posts/:id", to: ->(env) do
    posts = DB[:posts].where(id: env["router.params"][:id])
    if posts.any?
      params = Rack::Request.new(env).params
      begin
        posts.update(params)
        [200, {}, [DB[:posts].first]]
      rescue => error
        [422, {}, [error.to_json]]
      end
      [200, {}, [DB[:posts].first(id: env["router.params"][:id]).to_json]]
    else
      [404, {}, []]
    end
  end

  # DELETE /posts/1
  delete "/posts/:id", to: ->(env) do
    posts = DB[:posts].where(id: env["router.params"][:id])
    if posts.any?
      begin
        posts.delete
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
