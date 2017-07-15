require 'minitest/autorun'
require 'pry'
require_relative '../cpu'

class TestCPU < Minitest::Test
  def setup
    @cpu = CPU.new
  end

  def test_all_registers_are_zerod
    (0..15).each do |i|
      assert_equal @cpu.registers[i], 0
    end
    assert_equal @cpu.acc, 0 
    assert_equal @cpu.carry, 0
    assert_equal @cpu.data_ptr, 0
    assert_equal @cpu.code_ptr, 0
  end

  def test_simple_instruction
    @cpu.run('DA 00 BF AF')
    assert_equal @cpu.R15, 0xA
    assert_equal @cpu.acc, 0xA
  end

  def test_nop
    @cpu.run('00')
  end

  def test_jcn
    @cpu.carry = 1
    @cpu.run('16 03 F4')
    assert_equal 0, @cpu.acc
  end

  def test_jun
    @cpu.run('40 03 F4')
    assert_equal 0, @cpu.acc # jun opcode should jump around the acc inc instruction
  end

  def test_ldm
    @cpu.run('D5')
    assert_equal @cpu.acc, 0x5
  end

  def test_ld
    @cpu.registers[1] = 0x4
    @cpu.run('A1')
    assert_equal @cpu.acc, 0x4
  end

  def test_xch
    @cpu.registers[15] = 0x7
    @cpu.acc = 0xD
    @cpu.run('BF')
    assert_equal @cpu.acc, 0x7
    assert_equal @cpu.R15, 0xD
  end

  def test_clb
    @cpu.carry = 1
    @cpu.acc = 0x5
    @cpu.run('F0')
    assert_equal @cpu.carry, 0
    assert_equal @cpu.acc, 0
  end

  def test_clc
    @cpu.carry = 1
    assert_equal @cpu.carry, 1
    @cpu.run('F1')
    assert_equal @cpu.carry, 0
    assert_equal @cpu.acc, 0
  end

  def test_iac_no_overflow
    @cpu.run('F2')
    assert_equal @cpu.acc, 1
    assert_equal @cpu.carry, 0
  end

  def test_iac_overflow
    @cpu.acc = 0xF
    @cpu.run('F2')
    assert_equal @cpu.acc, 0
    assert_equal @cpu.carry, 1
  end

  def test_cmc
    @cpu.carry = 0
    @cpu.run('F3')
    assert_equal @cpu.carry, 1
    @cpu.run('F3')
    assert_equal @cpu.carry, 0
  end

  def test_cma
    @cpu.acc = 0xA
    @cpu.run('F4')
    assert_equal @cpu.acc, 0x5
  end

  def test_ral
    @cpu.acc = 0b0010
    @cpu.carry = 1
    @cpu.run('F5')
    assert_equal @cpu.carry, 0
    assert_equal @cpu.acc, 0b0101
  end

  def test_rar
    @cpu.acc = 0b0011
    @cpu.carry = 1
    @cpu.run('F6')
    assert_equal @cpu.carry, 1
    assert_equal @cpu.acc, 0b1001
  end

  def test_dac_no_borrow
    @cpu.acc = 0xF
    @cpu.carry = 0
    @cpu.run('F8')
    assert_equal @cpu.acc, 0xE
    assert_equal @cpu.carry, 1
  end

  def test_dac_borrow
    @cpu.acc = 0x0
    @cpu.carry = 0
    @cpu.run('F8')
    assert_equal @cpu.acc, 0xF
    assert_equal @cpu.carry, 0
  end

  def test_tcs
    @cpu.carry = 0
    @cpu.run('F9')
    assert_equal @cpu.acc, 9
    assert_equal @cpu.carry, 0

    @cpu.carry = 1
    @cpu.run('F9')
    assert_equal @cpu.acc, 10
    assert_equal @cpu.carry, 0
  end

  def test_stc
    assert_equal @cpu.carry, 0
    @cpu.run('FA')
    assert_equal @cpu.carry, 1
  end
end
