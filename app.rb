# frozen_string_literal: true
Encoding.default_external = 'UTF-8'
require 'sinatra'
require 'sinatra/reloader'
require 'json'

require 'net/http'
require 'uri'
require 'thread/pool'

require './content_controller'

$large_contents = [
 { id: 'demos', target: 'localhost', port:'8002', name: 'デモ', is_alive:false, selected: false, unselect_img: 'assets/demo.jpg', select_img: 'assets/demo.jpg', press_img: 'assets/demo.jpg' },
 { id: 'rs_server', target: 'localhost', port:'8002', name: 'カメラ', is_alive:false, selected: false, unselect_img: 'assets/bunshin.png', select_img: 'assets/bunshin.png', press_img: 'assets/bunshin.png' },
 { id: 'iguchi', target: 'localhost', port:'8002', name: 'キーボード', is_alive:false, selected: false, unselect_img: 'assets/keyboad.jpg', select_img: 'assets/keyboad.jpg', press_img: 'assets/keyboad.jpg' }
]

$small_contents = [
  #{ id: 'screen_saver', target: 'mori-san.local', port:'5001', name: 'デモ', is_alive:false, selected: false, unselect_img: 'assets/kit_btn_demo_off.png', select_img: 'assets/kit_btn_demo_on.png', press_img: 'assets/kit_btn_demo_press.png' }
]

$light_off_contents = [
  { id: 'alldisable', target: 'localhost', port:'8002', name: '消灯', is_alive:true, selected: true, unselect_img: 'assets/kit_btn_led_on.png', select_img: 'assets/kit_btn_led_off.png', press_img: 'assets/kit_btn_led_press.png' }
]

$contents = $large_contents + $small_contents + $light_off_contents

##
# Server program
class App < Sinatra::Base
  register Sinatra::Reloader
  enable :sessions
  set :bind, '0.0.0.0'# 外部アクセス可
  set :port, 8080

  def initialize
    super
    #led_controller's hostname and port will overwrite by content_controller's status response.
    @content_countroller = ContentController.new $contents
  end

  get '/' do
    @content_countroller.switch 'alldisable'

    @large_contents = $large_contents
    @small_contents = $small_contents
    @light_off_contents = $light_off_contents
    haml :index, locals: { title: '3D LED' }
  end

  get '/status' do
    # @content_countroller.status.to_json
  end

  post '/select' do
    id = params['id']
    @content_countroller.switch id
    return true 
  end

end
