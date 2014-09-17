require "rubygems"
require "json"
require "net/http"
require "uri"
require 'libdevinput'

EVIOCGRAB = 1074021776
DevInput.class_eval { attr_reader :dev }

def request_json(url)
  uri = URI.parse(url)
 
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new(uri.request_uri)
 
response = http.request(request)
 
if response.code == "200"
  result = JSON.parse(response.body)
  #result.each do |doc|
  #  puts doc["id"] #reference properties like this
  #  puts doc # this is the result in object form
  #  puts ""
  #  puts ""
  #end
  puts result
  else
    puts "ERROR!!!"
  end
end

def process_barcode(code)
  puts "Searching for #{code}"
  puts 'Searching in outpan' 
  request_json("http://www.outpan.com/api/get_product.php?barcode=#{code}")
end

def read_barcode2
  @barcode_scanner = DevInput.new('/dev/hidraw0')
  # Grab barcode scanner exclusively (so keypress events aren't heard by Linux)
  #@barcode_scanner.dev.ioctl(EVIOCGRAB, 1)
  @barcode_scanner.each do |event|
    puts "got event #{event}"
    if event.type == 1 && event.value == 1
      if event.code == 28 # Enter key 
        puts "END"
      end
    end	
  end
end

def read_barcode
  done = false 
  data = []
  str = ''
  dev = File.open("/dev/hidraw0")
  while !done
    str += dev.read(4) # 1 Byte lesen, blockt wenn noch keine da sind
    done = true if str['\rn'] != nil || str['\r'] != nil || str['\n']
    puts str
    #if str
    #  data << str
    #  puts "received char #{str}"
    #  done == true if str == '\rn'
    #end
    # Daten verarbeiten
  end
  code = data.unpack("A").join 
  puts "code: #{code} "
  #process_barcode(code)
end

while true
 puts "Enter barcode:"
 read_barcode2
end
