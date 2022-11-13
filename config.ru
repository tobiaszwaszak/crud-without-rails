require "hanami/router"
require "rom"
require "JSON"
require "faker"
require "byebug"
require "dry-validation"
require "rom-repository"

rom = ROM.container(:sql, "sqlite::memory") do |conf|
  conf.default.create_table(:posts) do
    primary_key :id
    column :name, String, null: false
    column :body, String, null: false
  end

  class Posts < ROM::Relation[:sql]
    schema(infer: true)
  end

  conf.register_relation(Posts)
end

33.times do
  posts = rom.relations[:posts]
  posts.changeset(:create, name: Faker::FunnyName.four_word_name, body: Faker::Books::Lovecraft.paragraph).commit
end

class PostContract < Dry::Validation::Contract
  params do
    required(:name).filled(:string)
    required(:body).filled(:string)
  end
end

app = Hanami::Router.new do
  # GET /posts
  get "/posts", to: ->(env) { [200, {}, [rom.relations[:posts].to_a.to_json]] }

  # GET /posts/1
  get "/posts/:id", to: ->(env) do
    post = rom.relations[:posts].by_pk(env["router.params"][:id]).first
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

      command = rom.relations[:posts].command(:create)
      post_entity = command.call(contract.to_h)

      [201, {}, [post_entity.to_json]]
    rescue => error
      [422, {}, [error.to_json]]
    end
  end

  # PUT /posts/1
  put "/posts/:id", to: ->(env) do
    post = rom.relations[:posts].by_pk(env["router.params"][:id])
    if post.exist?
      params = Rack::Request.new(env).params
      begin
        command = post.command(:update)
        post_entity = command.call(params)
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
    post = rom.relations[:posts].by_pk(env["router.params"][:id])
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
