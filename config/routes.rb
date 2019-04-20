Rails.application.routes.draw do
  root 'img_analyze#home'
  post '/result', to: 'img_analyze#ajax_analize'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
