require 'benchmark/ips'

def parse_a(string)
  marshal  = string[2, 12].strip
  compress = string[15] == '1'.freeze

  [Kernel.const_get(marshal), compress, string[18..-1]]
end

def parse_b(marked)
  prefix = marked[0, 32].scrub('*'.freeze)[/R\|(.*)\|R/, 1]
  offset = prefix.size + 4

  marshal, c_name, _ = prefix.split('|'.freeze)

  compress = c_name == 'true'.freeze
  # Kernel.const_get won't work here because marshal is "Marshal      0"
  [marshal, compress, marked[offset..-1]]
end

require 'json'
require 'oj'
SERIALIZERS = {Marshal => 0x1, JSON => 0x2, Oj => 0x3}.freeze
DESERIALIZERS = SERIALIZERS.invert.freeze
COMPRESSED_FLAG = 0x8
MARSHAL_FLAG = 0x3
# Example flag for a compressed string serialized with marshal
BINARY_FLAG = [SERIALIZERS[Marshal] | COMPRESSED_FLAG].pack('C')

STR = 'R|Marshal      0|Rafdlkadfjadfj asdlkfjasdlfkj asdlfkjdasflkjadsflkjadslkjfadslkjfasdlkjfadlskjf laksdjflkajsdflkjadsflkadjsfladskjf laksjflakdjfalsdkjfadlskjf laksdjflkajdsflk j'
STR2 = BINARY_FLAG << 'Rafdlkadfjadfj asdlkfjasdlfkj asdlfkjdasflkjadsflkjadslkjfadslkjfasdlkjfadlskjf laksdjflkajsdflkjadsflkadjsfladskjf laksjflakdjfalsdkjfadlskjf laksdjflkajdsflk j'


def parse_c(binary_string)
  flags = binary_string[0].unpack('C').first
  [DESERIALIZERS[flags & MARSHAL_FLAG], flags & COMPRESSED_FLAG, binary_string[1..-1]]
end

Benchmark.ips do |x|
  x.report('a') { parse_a(STR) }
  x.report('b') { parse_b(STR) }
  x.report('c') { parse_c(STR2) }

  x.compare!
end
