require 'benchmark/ips'

def compose_a(marshal, compress)
  prefix = ''
  prefix << 'R|'.freeze
  prefix << marshal.name.ljust(24)
  prefix << (compress ? '1'.freeze : '0'.freeze)
  prefix << 1
  prefix << '|R'.freeze
end

def compose_b(marshal, compress)
  "R|#{marshal.name.ljust(24)}#{compress ? '1'.freeze : '0'.freeze}1|R"
end

def compose_c(marshal, compress)
  name = marshal.name.ljust(24)
  comp = compress ? '1'.freeze : '0'.freeze

  "R|#{name}#{comp}1|R"
end

require 'json'
require 'oj'
SERIALIZERS = {Marshal => 0x1, JSON => 0x2, Oj => 0x3}.freeze
COMPRESSED_FLAG = 0x8

# Uses binary flags to store compressions
def compose_d(marshal, compress)
  # Example flag byte, uses the following layout to store metadata
  # | 0000 | 0 | 000 | # => four unused bits, 1 compression bit, 3 bits for serializer, allow up to 8 different marshalers
  flags = SERIALIZERS[marshal]
  flags |= COMPRESSED_FLAG if compress
  [flags].pack('C')
end

Benchmark.ips do |x|
  x.report('a') { compose_a(Marshal, true) }
  x.report('b') { compose_b(Marshal, true) }
  x.report('c') { compose_c(Marshal, true) }
  x.report('d') { compose_d(Marshal, true) }

  x.compare!
end
