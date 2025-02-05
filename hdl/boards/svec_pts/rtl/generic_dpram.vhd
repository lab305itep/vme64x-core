-------------------------------------------------------------------------------
-- Title      : Parametrizable dual-port synchronous RAM (Xilinx version)
-- Project    : Generics RAMs and FIFOs collection
-------------------------------------------------------------------------------
-- File       : generic_dpram.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN BE-CO-HT
-- Created    : 2011-01-25
-- Last update: 2012-03-16
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: True dual-port synchronous RAM for Xilinx FPGAs with:
-- - configurable address and data bus width
-- - byte-addressing mode (data bus width restricted to multiple of 8 bits)
-- Todo:
-- - loading initial contents from file
-- - add support for read-first/write-first address conflict resulution (only
--   supported by Xilinx in VHDL templates)
-------------------------------------------------------------------------------
-- Copyright (c) 2011 CERN
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2011-01-25  1.0      twlostow        Created
-- 2012-03-13  1.1      wterpstra       Added initial value as array
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library work;
use work.genram_pkg.all;
use work.memory_loader_pkg.all;

entity generic_dpram is

  generic (
    -- standard parameters
    g_data_width : natural := 32;
    g_size       : natural := 1024;

    g_with_byte_enable         : boolean;
    g_addr_conflict_resolution : string  := "read_first";
    g_init_file                : string  := "";
    g_init_value               : t_generic_ram_init := c_generic_ram_nothing;
    g_dual_clock               : boolean;
    g_fail_if_file_not_found   : boolean := true
    );

  port (
    rst_n_i : in std_logic := '1';      -- synchronous reset, active LO

    -- Port A
    clka_i : in  std_logic;
    bwea_i : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
    wea_i  : in  std_logic;
    aa_i   : in  std_logic_vector(f_log2_size(g_size)-1 downto 0);
    da_i   : in  std_logic_vector(g_data_width-1 downto 0);
    qa_o   : out std_logic_vector(g_data_width-1 downto 0);
    -- Port B

    clkb_i : in  std_logic;
    bweb_i : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
    web_i  : in  std_logic;
    ab_i   : in  std_logic_vector(f_log2_size(g_size)-1 downto 0);
    db_i   : in  std_logic_vector(g_data_width-1 downto 0);
    qb_o   : out std_logic_vector(g_data_width-1 downto 0)
    );

end generic_dpram;



architecture syn of generic_dpram is

  component generic_dpram_sameclock
    generic (
      g_data_width               : natural;
      g_size                     : natural;
      g_with_byte_enable         : boolean;
      g_addr_conflict_resolution : string;
      g_init_file                : string;
      g_init_value               : t_generic_ram_init;
      g_fail_if_file_not_found   : boolean);
    port (
      rst_n_i : in  std_logic := '1';
      clk_i   : in  std_logic;
      bwea_i  : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
      wea_i   : in  std_logic;
      aa_i    : in  std_logic_vector(f_log2_size(g_size)-1 downto 0);
      da_i    : in  std_logic_vector(g_data_width-1 downto 0);
      qa_o    : out std_logic_vector(g_data_width-1 downto 0);
      bweb_i  : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
      web_i   : in  std_logic;
      ab_i    : in  std_logic_vector(f_log2_size(g_size)-1 downto 0);
      db_i    : in  std_logic_vector(g_data_width-1 downto 0);
      qb_o    : out std_logic_vector(g_data_width-1 downto 0));
  end component;  

  component generic_dpram_dualclock
    generic (
      g_data_width               : natural;
      g_size                     : natural;
      g_with_byte_enable         : boolean;
      g_addr_conflict_resolution : string;
      g_init_file                : string;
      g_init_value               : t_generic_ram_init;
      g_fail_if_file_not_found   : boolean);
    port (
      rst_n_i : in  std_logic := '1';
      clka_i  : in  std_logic;
      bwea_i  : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
      wea_i   : in  std_logic;
      aa_i    : in  std_logic_vector(f_log2_size(g_size)-1 downto 0);
      da_i    : in  std_logic_vector(g_data_width-1 downto 0);
      qa_o    : out std_logic_vector(g_data_width-1 downto 0);
      clkb_i  : in  std_logic;
      bweb_i  : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
      web_i   : in  std_logic;
      ab_i    : in  std_logic_vector(f_log2_size(g_size)-1 downto 0);
      db_i    : in  std_logic_vector(g_data_width-1 downto 0);
      qb_o    : out std_logic_vector(g_data_width-1 downto 0));
  end component;

begin

  gen_single_clk : if(g_dual_clock = false) generate
  U_RAM_SC: generic_dpram_sameclock
    generic map (
      g_data_width               => g_data_width,
      g_size                     => g_size,
      g_with_byte_enable         => g_with_byte_enable,
      g_addr_conflict_resolution => g_addr_conflict_resolution,
      g_init_file                => g_init_file,
	  g_init_value               => g_init_value,
      g_fail_if_file_not_found   => g_fail_if_file_not_found)
    port map (
      rst_n_i => rst_n_i,
      clk_i   => clka_i,
      bwea_i  => bwea_i,
      wea_i   => wea_i,
      aa_i    => aa_i,
      da_i    => da_i,
      qa_o    => qa_o,
      bweb_i  => bweb_i,
      web_i   => web_i,
      ab_i    => ab_i,
      db_i    => db_i,
      qb_o    => qb_o); 

    
  end generate gen_single_clk;

  gen_dual_clk : if(g_dual_clock = true) generate
    U_RAM_DC: generic_dpram_dualclock
      generic map (
        g_data_width               => g_data_width,
        g_size                     => g_size,
        g_with_byte_enable         => g_with_byte_enable,
        g_addr_conflict_resolution => g_addr_conflict_resolution,
        g_init_file                => g_init_file,
   	    g_init_value               => g_init_value,
        g_fail_if_file_not_found   => g_fail_if_file_not_found)
      port map (
        rst_n_i => rst_n_i,
        clka_i  => clka_i,
        bwea_i  => bwea_i,
        wea_i   => wea_i,
        aa_i    => aa_i,
        da_i    => da_i,
        qa_o    => qa_o,
        clkb_i  => clkb_i,
        bweb_i  => bweb_i,
        web_i   => web_i,
        ab_i    => ab_i,
        db_i    => db_i,
        qb_o    => qb_o);
  end generate gen_dual_clk;

end syn;
