Bananajour.require_gem('net-mdns', 'net/dns/mdns-sd')

require 'thread'
require 'timeout'

Thread.abort_on_exception = true

# Generic bonjour browser
#
# Example use:
#
#   browser = BonjourBrowser.new("_git._tcp,_bananajour")
#   loop do
#     sleep(1)
#     pp browser.replies.map {|r| r.name}
#   end
#
# Probably gem-worthy
class Bananajour::Bonjour::Browser
  def initialize(service)
    @service = service
    @mutex = Mutex.new
    @replies = {}
    @threads = []
    @browser = nil
    watch!
  end
  
  def replies
    @mutex.synchronize { @replies.values }
  end
  
  def stop
    @browser.stop
    @threads.each { |t| t.stop }
  end
  
  private
  
  def watch!
    @browser = DNSSD.browse(@service) do |reply|
      begin
        resolver = DNSSD.resolve(reply.name, reply.type, reply.domain) do |r_reply|
          begin
            @mutex.synchronize do
              if reply.flags.to_i > 0
                @replies[r_reply.fullname] = r_reply
              else
                @replies.delete(r_reply.fullname)
              end
            end
          rescue
            @mutex.synchronize { puts $!; puts $!.backtrace }
          end
        end
        @mutex.synchronize { @threads << resolver }
      rescue
        @mutex.synchronize { puts $!; puts $!.backtrace }
      end
    end
  end
end