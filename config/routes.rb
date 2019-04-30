Rails.application.routes.draw do
  root 'img_analyze#home'
  get  '/color_result', to: 'img_analyze#home'
  post '/color_result', to: 'img_analyze#ajax_analize_color'
  get  '/face_result', to: 'img_analyze#home'
  post '/face_result', to: 'img_analyze#ajax_analize_face'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
