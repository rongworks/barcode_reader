require "rubygems"
require "json"
require "net/http"
require "uri"

## map raw hid input to respective keys
$hid = { 4 => 'a', 5 => 'b', 6 => 'c', 7 => 'd', 8 => 'e', 9 => 'f', 10 => 'g', 11 => 'h', 12 => 'i', 13 => 'j', 14 => 'k', 15 => 'l', 16 => 'm', 17 => 'n', 18 => 'o', 19 => 'p', 20 => 'q', 21 => 'r', 22 => 's', 23 => 't', 24 => 'u', 25 => 'v', 26 => 'w', 27 => 'x', 28 => 'y', 29 => 'z', 30 => '1', 31 => '2', 32 => '3', 33 => '4', 34 => '5', 35 => '6', 36 => '7', 37 => '8', 38 => '9', 39 => '0', 44 => ' ', 45 => '-', 46 => '=', 47 => '[', 48 => ']', 49 => '\\', 51 => ';' , 52 => '\'', 53 => '~', 54 => ',', 55 => '.', 56 => '/'  }

## input map with preceeding shift-key
$hid2 = { 4 => 'A', 5 => 'B', 6 => 'C', 7 => 'D', 8 => 'E', 9 => 'F', 10 => 'G', 11 => 'H', 12 => 'I', 13 => 'J', 14 => 'K', 15 => 'L', 16 => 'M', 17 => 'N', 18 => 'O', 19 => 'P', 20 => 'Q', 21 => 'R', 22 => 'S', 23 => 'T', 24 => 'U', 25 => 'V', 26 => 'W', 27 => 'X', 28 => 'Y', 29 => 'Z', 30 => '!', 31 => '@', 32 => '#', 33 => '$', 34 => '%', 35 => '^', 36 => '&', 37 => '*', 38 => '(', 39 => ')', 44 => ' ', 45 => '_', 46 => '+', 47 => '{', 48 => '}', 49 => '|', 51 => ' =>' , 52 => '"', 53 => '~', 54 => '<', 55 => '>', 56 => '?'  }

# send json request to provided url, process result (wip)
def request_json(url)
  uri = URI.parse(url)
 
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
 
  response = http.request(request)
 
  if response.code == "200"
    result = JSON.parse(response.body)
    #result.each do |doc|
      puts " === #{request} ==="	
      puts "Name: \n #{result["name"]}" #reference properties like this
      puts "Description: \n #{result["description"]}"
    #end
  else
    puts "ERROR!!!"
  end
end

# Search database(s) for given barcode
def process_barcode(code)
  puts "Searching for #{code}"
  puts 'Searching in outpan' 
  request_json("http://www.outpan.com/api/get_product.php?barcode=#{code}")
end

# read raw hid input, map to characters until 'return'(==40) is read
def read_barcode
  f = open('/dev/hidraw0','rb')
  done  = false
  code = ''
  while !done
    buf = f.read(8)
    buf.each_char do |char|
      c = char.ord
      if c == 40
        done = true
      else
        puts c if c > 0
        code += $hid[c] if c > 0
      end 
    end
  end
  puts "CODE: #{code}"
  return code
end

# provide example barcode, so I don't need scanner in development
def sample_barcode
  '078915030900'
end

#while true
 #puts "Enter barcode:"
 #read_barcode
 code = sample_barcode
 puts "Code: #{code}"
 process_barcode(code)
#end
