require 'timeout'
require 'resolv-replace'
require './my_utils'

class ContentController
  def initialize(contents, timeout=0.1)
    # 同時にセレクトリクエストをPOSTするクライアントは1つである前提
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
    @contents.each do |c|
      c[:selected] = c[:id] == selected_id
      next unless c[:selected]
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
      http.use_ssl = false
      req = Net::HTTP::Get.new(uri.request_uri)
      
       Timeout::timeout(@timeout) do
        res = http.request(req)
        state = JSON.parse(res.body)
        c[:is_alive] =  state["is_alive"]

      end
    rescue => e
      p c[:target] + ": " + e.inspect
      c[:is_alive] = false
    end
  end
end
