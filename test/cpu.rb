require 'minitest/autorun'
require 'pry'
require_relative '../cpu'

class TestCPU < Minitest::Test
  def setup
    @cpu = CPU.new
  end

  def test_all_registers_are_zerod
    (0..16).each do |i|
      assert_equal @cpu.registers[i].to_s, '0' * 4
    end
    assert_equal @cpu.acc.to_s, '0' * 4
    assert_equal @cpu.carry.to_s, '0'
    assert_equal @cpu.data_ptr.to_s, '0' * 8
    assert_equal @cpu.code_ptr.to_s, '0' * 12
  end

  def test_simple_instruction
    @cpu.run('DA 00 BF AF')
    assert_equal @cpu.R15, 0xA
    assert_equal @cpu.acc, 0xA
  end

  def test_nop
    @cpu.run('00')
  end

  def test_ldm
    @cpu.run('D5')
    assert_equal @cpu.acc, 0x5
  end

  def test_ld
    @cpu.registers[1].bits = 0x4
    @cpu.run('A1')
    assert_equal @cpu.acc, 0x4
  end

  def test_xch
    @cpu.registers[15].bits = 0x7
    @cpu.acc.bits = 0xD
    @cpu.run('BF')
    assert_equal @cpu.acc, 0x7
    assert_equal @cpu.R15, 0xD
  end

  def test_clb
    @cpu.carry.bit = 1
    @cpu.acc.bits = 0x5
    @cpu.run('F0')
    assert_equal @cpu.carry, 0
    assert_equal @cpu.acc, 0
  end

  def test_clc
    @cpu.carry.bit = 1
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
    @cpu.acc.bits = 0xF
    @cpu.run('F2')
    assert_equal @cpu.acc, 0
    assert_equal @cpu.carry, 1
  end

  def test_dac_no_borrow
    @cpu.acc.bits = 0xF
    @cpu.carry.bits = 0
    @cpu.run('F8')
    assert_equal @cpu.acc, 0xE
    assert_equal @cpu.carry, 1
  end

  def test_dac_borrow
    @cpu.acc.bits = 0x0
    @cpu.carry.bits = 0
    @cpu.run('F8')
    assert_equal @cpu.acc, 0xF
    assert_equal @cpu.carry, 0
  end

  def test_stc
    assert_equal @cpu.carry, 0
    @cpu.run('FA')
    assert_equal @cpu.carry, 1
  end
end
