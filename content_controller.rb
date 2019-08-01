require 'timeout'
require 'resolv-replace'

require './my_utils'

class ContentController
  def initialize(contents, led_controller, timeout=0.1)
    # 同時にセレクトリクエストをPOSTするクライアントは1つである前提
    @led_controller = led_controller
    @contents = contents
    @contents.each  do |c|
      c[:pool] = Thread::Pool.new(1)
    end

    @timeout = timeout
  end

  def status
    @contents.each do |c|
      next unless c[:pool].done? 
      c[:pool].process { update_status(c)} 
    end
    @contents
  end

  def switch(selected_id)
    @led_controller.light_off
    @contents.each do |c|
      c[:selected] = c[:id] == selected_id
      # next unless c[:selected]
      # next unless c[:pool].done? 
      # next unless c[:is_alive]
      c[:pool].process { enable_content(c, selected_id) }
    end
  end

  private

  def enable_content(c, selected_id)
    begin
      url = 'http://' + MyUtils.get_ip_from_hostname(c[:target]) +'/api/enable' + '?name=' + c[:id]
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, c[:port])
      http.set_debug_output $stderr
      http.use_ssl = false
      req = Net::HTTP::Post.new(uri.request_uri)

      req['Content-Type'] = 'application/json' # httpリクエストヘッダの追加
      if c[:selected]
        config = ({'enable': true}).to_json
      else
        config = ({'enable': false}).to_json
      end
      req.body = config # リクエストボディーにJSONをセット

      Timeout::timeout(@timeout) do
        res = http.request(req)
        c[:is_alive] = res.code == "200"
      end
    rescue => e
      p c[:target] + ": " + e.inspect
      c[:is_alive] = false
    end
  end

  def update_status(c)
    begin
      url = 'http://' + MyUtils.get_ip_from_hostname(c[:target]) +'/api/status' + '?name=' +c[:id]
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, c[:port])
      http.set_debug_output $stderr
      http.use_ssl = false
      req = Net::HTTP::Get.new(uri.request_uri)
      
       Timeout::timeout(@timeout) do
        res = http.request(req)
        state = JSON.parse(res.body)
        c[:is_alive] =  state["is_alive"]

      #   if res.code == "200"
      #     # state = JSON.parse(res.body)
      #     # host, port = state["enable"].split(":")
      #     # unless @led_controller.is_host_and_port_same?(host, port)
      #     #   p "warning.. deferrent hosts or ports is mixed in targets. "
      #     # end
      #     # @led_controller.set_host_and_port(host, port)

      #     # enable_content(c, c[:selected])
      #   end

      end
    rescue => e
      p c[:target] + ": " + e.inspect
      c[:is_alive] = false
    end
  end
end
