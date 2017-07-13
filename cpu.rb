require 'pry'

class CPU
  attr_accessor :registers, :acc, :carry, :data_ptr, :code_ptr
  def initialize
    @registers = Array.new(16) { 0 }
    @acc = 0 # accumulator
    @carry = 0
    @data_ptr = 0
    @code_ptr = 0
  end

  def run(object_code)
    object_code.delete(' ').chars.map(&:hex).each_slice(2) do |high_nibble, low_nibble|
      if high_nibble < 0xE
        send(opcodes[high_nibble], low_nibble)
      else
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
    self.acc = arg
  end

  def i_LD(arg)
    self.acc = registers[arg].dup
  end

  def i_XCH(arg)
    self.acc, self.registers[arg] = registers[arg], acc
  end

  def i_CLB
    self.carry = 0
    self.acc = 0
  end

  def i_CLC
    self.carry = 0
  end

  def i_IAC
    if acc == 0xF
      self.acc = 0
      self.carry = 1
    else
      self.acc += 1
      self.carry = 0
    end
  end

  def i_CMC
    self.carry ^= 1
  end

  def i_CMA
    self.acc ^= 0xf
  end

  def i_RAL
    tmp = self.carry
    self.carry = acc[3]
    self.acc = [acc[2], acc[1], acc[0], tmp].join.to_i(2)
  end

  def i_RAR
    tmp = self.carry
    self.carry = acc[0]
    self.acc = [tmp, acc[3], acc[2], acc[1]].join.to_i(2)
  end

  def i_DAC
    if acc == 0x0
      self.acc = 0xF
      self.carry = 0
    else
      self.acc -= 1
      self.carry = 1
    end
  end

  def i_STC
    self.carry = 1
  end

  16.times do |i|
    define_method("R#{i}") { @registers[i] }
  end

  def memory_dump
    16.times do |i|
      puts "R#{i} 0x#{registers[i]}"
    end
    puts "Acc:\t#{acc}"
    puts "Carry: #{carry}"
    puts "Data pointer: #{data_ptr}"
    puts "Code pointer: #{code_ptr}"
  end
end


if __FILE__ == $PROGRAM_NAME
  cpu = CPU.new.run(ARGV[0])
  cpu.memory_dump
  binding.pry
end
