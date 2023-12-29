Rails.application.routes.draw do
  mount API => '/'
  mount GrapeSwaggerRails::Engine => '/swagger' if Rails.env.development?
end
