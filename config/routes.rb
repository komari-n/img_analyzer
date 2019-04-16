Rails.application.routes.draw do
  root 'img_analyzer#home'
  post '/result', to: 'img_analyzer#analize'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
