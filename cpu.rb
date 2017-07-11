require 'pry'

class CPU
  attr_accessor :registers, :acc, :carry, :data_ptr, :code_ptr
  def initialize
    @registers = (0..16).map { BitField.new(length: 4) }
    @acc = BitField.new(length: 4) # accumulator
    @carry = BitField.new(length: 1)
    @data_ptr = BitField.new(length: 8)
    @code_ptr = BitField.new(length: 12)
  end

  def run(object_code)
    object_code.delete(' ').chars.map(&:hex).each_slice(2) do |high_nibble, low_nibble|
      if high_nibble < 0xE
        puts "Instruction #{high_nibble}, arg #{low_nibble}"
        send(opcodes[high_nibble], low_nibble)
      else
        puts "Instruction #{high_nibble}#{low_nibble}"
        send(opcodes[(high_nibble * 16 + low_nibble)])
      end
    end
    self
  end

  def opcodes
    @opcodes ||= {
      0x0 => :i_NOP, # No Operation
      0xD => :i_LDM, # Load Immediate
      0xA => :i_LD,  # Load
      0xB => :i_XCH, # Exchange
      0xF0 => :i_CLB, # Clear Both
      0xF1 => :i_CLC, # Clear Carry
      0xF2 => :i_IAC, # Increment Accumulator
      0xF3 => :i_CMC, # Complement Carry
      0xF4 => :i_CMA, # Complement Accumulator
      0xF5 => :i_RAL, # Rotate Left
      0xF6 => :i_RAR, # Rotate Right
      0xF8 => :i_DAC, # Decrement Accumulator
      0xFA => :i_STC, # Set Carry
    }
  end

  def i_NOP(_); end

  def i_LDM(arg)
    acc.bits = arg
  end

  def i_LD(arg)
    self.acc = registers[arg].dup
  end

  def i_XCH(arg)
    self.acc, self.registers[arg] = registers[arg], acc
  end

  def i_CLB
    carry.bit = 0
    acc.bits = 0
  end

  def i_CLC
    carry.bit = 0
  end

  def i_IAC
    if acc == 0xF
      acc.bits = 0
      carry.bit = 1
    else
      acc.bits = acc.to_hex + 1
      carry.bit = 0
    end
  end

  def i_CMC
    carry == 0 ? carry.bit = 1 : carry.bit = 0
  end

  def i_CMA
    acc.set(acc.map { |bit| bit == 0 ? bit = 1 : bit = 0 })
  end

  def i_RAL
    tmp = carry.to_hex
    carry.bit = acc[0]
    acc.set([acc[1], acc[2], acc[3], tmp])
  end

  def i_RAR
    tmp = carry.to_hex
    carry.bit = acc[3]
    acc.set([tmp, acc[0], acc[1], acc[2]])
  end

  def i_DAC
    if acc == 0x0
      acc.bits = 0xF
      carry.bit = 0
    else
      acc.bits = acc.to_hex - 1
      carry.bit = 1
    end
  end

  def i_STC
    carry.bit = 1
  end

  16.times do |i|
    define_method("R#{i}") { @registers[i] }
  end

  def memory_dump
    16.times do |i|
      puts "R#{i} 0x#{registers[i].to_hex.to_s(16).upcase}"
    end
    puts "Acc:\t#{acc}"
    puts "Carry: #{carry}"
    puts "Data pointer: #{data_ptr}"
    puts "Code pointer: #{code_ptr}"
  end
end

module ArrayExtension
  refine Array do
    def rjust(n, x)
      Array.new([0, n - length].max, x) + self
    end
  end
end

class BitField
  using ArrayExtension
  include Enumerable

  def initialize(length:, value: 0)
    @bits = Array.new(length) { value }
    @length = length
  end

  def bits=(hex_value)
    @bits = hex_value.to_s(2).chars.map(&:to_i).last(@length).rjust(@length, 0)
  end
  alias bit= bits=

  def set(array_of_ints)
    @bits = array_of_ints.last(@length)
  end

  def to_s
    @bits.join
  end

  def to_hex
    @bits.join.to_i(2)
  end

  def ==(other)
    to_hex == other
  end

  def [](i)
    @bits[i]
  end

  def each(&block)
    @bits.each(&block)
  end
end

if __FILE__ == $PROGRAM_NAME
  cpu = CPU.new.run(ARGV[0])
  cpu.memory_dump
  binding.pry
end
