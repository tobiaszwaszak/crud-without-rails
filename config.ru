require "hanami/router"

app = Hanami::Router.new do
  get     "/posts", to: ->(env) { [200, {}, ["Hello World"]] }
  post    "/posts", to: ->(env) { [200, {}, ["Hello World"]] }
  patch   "/posts", to: ->(env) { [200, {}, ["Hello World"]] }
  delete  "/hanami", to: ->(env) { [200, {}, ["Hello World"]] }
end

run app
