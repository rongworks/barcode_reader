require "rubygems"
require "json"
require "net/http"
require "uri"

class Control
  CHECK_IN = 'xcheckinx'
  CHECK_OUT = 'xcheckoutx'
  EXIT = 'xexitx'
end
class State
  CHECK_IN = 0
  CHECK_OUT = 1
  TERMINATE = 2
end

## map raw hid input to respective keys
$hid = { 4 => 'a', 5 => 'b', 6 => 'c', 7 => 'd', 8 => 'e', 9 => 'f', 10 => 'g', 11 => 'h', 12 => 'i', 13 => 'j', 14 => 'k', 15 => 'l', 16 => 'm', 17 => 'n', 18 => 'o', 19 => 'p', 20 => 'q', 21 => 'r', 22 => 's', 23 => 't', 24 => 'u', 25 => 'v', 26 => 'w', 27 => 'x', 28 => 'y', 29 => 'z', 30 => '1', 31 => '2', 32 => '3', 33 => '4', 34 => '5', 35 => '6', 36 => '7', 37 => '8', 38 => '9', 39 => '0', 44 => ' ', 45 => '-', 46 => '=', 47 => '[', 48 => ']', 49 => '\\', 51 => ';' , 52 => '\'', 53 => '~', 54 => ',', 55 => '.', 56 => '/'  }

## input map with preceeding shift-key
$hid2 = { 4 => 'A', 5 => 'B', 6 => 'C', 7 => 'D', 8 => 'E', 9 => 'F', 10 => 'G', 11 => 'H', 12 => 'I', 13 => 'J', 14 => 'K', 15 => 'L', 16 => 'M', 17 => 'N', 18 => 'O', 19 => 'P', 20 => 'Q', 21 => 'R', 22 => 'S', 23 => 'T', 24 => 'U', 25 => 'V', 26 => 'W', 27 => 'X', 28 => 'Y', 29 => 'Z', 30 => '!', 31 => '@', 32 => '#', 33 => '$', 34 => '%', 35 => '^', 36 => '&', 37 => '*', 38 => '(', 39 => ')', 44 => ' ', 45 => '_', 46 => '+', 47 => '{', 48 => '}', 49 => '|', 51 => ' =>' , 52 => '"', 53 => '~', 54 => '<', 55 => '>', 56 => '?'  }

## Fooder variables
$fooder_url = 'https://sheltered-spire-4443.herokuapp.com/'
$check_in_url = $fooder_url+'check_in.json'
$check_out_url = $fooder_url+'check_out.json'

$api_key = 'fa373ff87266a7be6bc7a3465bcf57ef'

# Global variables
$state = State::CHECK_IN
$debug = false

# send json POST to fooder-server
def send_json(url,code)
  params = {'code' => code}
  uri = URI.parse(url)
  json_headers = {"Content-Type" => "application/json",
		 #"Accept" => "application/json",
                 "Authorization" => 'Token token="'+$api_key+'"'}
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  #http.set_debug_output($stdout)
  response = http.post(uri.path,params.to_json, json_headers)

  if response.code == "200" || response.code == "201"
    result = JSON.parse(response.body)
    puts " === STATUS: #{response.code} ===" if $debug
    puts response.body if $debug
    #end
  else
    puts "ERROR (#{response.code})!!! #{response.body}"
  end
end

# send json request to provided url, process result (wip)
def request_json(url)
  uri = URI.parse(url)

  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)

  response = http.request(request)

  if response.code == "200"
    result = JSON.parse(response.body)
    #result.each do |doc|
      puts " === #{code} ==="
      puts "Name: \n #{result["name"]}" #reference properties like this
      puts "Description: \n #{result["description"]}"
    #end
  else
    puts "ERROR!!! #{response.body}"
  end
end

# Search database(s) for given barcode
def barcode_lookup(code)
  puts 'Searching in outpan'
  request_json("http://www.outpan.com/api/get_product.php?barcode=#{code}")
end

# read raw hid input, map to characters until 'return'(==40) is read
def read_barcode
  # TODO: seems to read to frequently
  f = open('/dev/hidraw0','rb')
  done  = false
  code = ''
  input = []
  uppercase = false #last read char was 'Shift'
  while !done
    buf = f.read(8)
    buf.each_char do |char|
      c = char.ord
      input << c
      next if c <= 0
      if c == 40 # 'return' was send, code complete
        done = true
      else
        puts c if $debug
        if c == 2 # 'Shift key for Uppercase was send, use upper key values'
          #puts 'uppercase'
          uppercase = true
        else
          if uppercase
            code += $hid2[c]
            uppercase = false
          else
            code += $hid[c]
          end
        end
      end
    end
  end
  puts "INPUT: #{input}" if $debug
  puts "CODE: #{code}"
  return code
end

# provide example barcode, so I don't need scanner in development
def sample_barcode
  '078915030900'
end

def process_barcode(code)
  #XXX: downcase cause reading uppercase keys doesnt work as expected
  case code.downcase
  when '000000000001'
    puts "State: #{$state}"
  when Control::CHECK_IN
    $state = State::CHECK_IN
  when Control::CHECK_OUT
    $state = State::CHECK_OUT
  when Control::EXIT
    $state = State::TERMINATE
  else
    case $state
    when State::CHECK_IN
      send_json $check_in_url, code
    when State::CHECK_OUT
      send_json $check_out_url, code
    end
  end
end

def main_loop

  while $state != State::TERMINATE
    puts "=> State: #{$state}"
    code = read_barcode
    #puts "Code: #{code}"
    process_barcode code
  end
end

main_loop
