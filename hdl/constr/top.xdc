# 200MHz board clock
create_clock -name sysclk -period 5.0 [get_ports SYSCLK_P]

set_property PACKAGE_PIN AD12 [get_ports SYSCLK_P]
set_property IOSTANDARD LVDS [get_ports SYSCLK_P]
set_property PACKAGE_PIN AD11 [get_ports SYSCLK_N]
set_property IOSTANDARD LVDS [get_ports SYSCLK_N]

# GT system clock
create_clock -name gt_sysclk -period 6.4 [get_ports GT_SYSCLK_P]
set_property PACKAGE_PIN K28 [get_ports GT_SYSCLK_P]
set_property PACKAGE_PIN K29 [get_ports GT_SYSCLK_N]
set_property IOSTANDARD LVDS_25 [get_ports GT_SYSCLK_P]
set_property IOSTANDARD LVDS_25 [get_ports GT_SYSCLK_N]

# GT LOC
set_property LOC GTXE2_CHANNEL_X0Y10 [get_cells gtx_0_i/inst/gtx_0_init_i/gtx_0_i/gt0_gtx_0_i/gtxe2_i]

# Global IIC BUS
set_property PACKAGE_PIN K21 [get_ports IIC_SCL_MAIN]
set_property IOSTANDARD LVCMOS25 [get_ports IIC_SCL_MAIN]
set_property PACKAGE_PIN L21 [get_ports IIC_SDA_MAIN]
set_property IOSTANDARD LVCMOS25 [get_ports IIC_SDA_MAIN]
set_property PACKAGE_PIN P23 [get_ports IIC_MUX_RESET_B]
set_property IOSTANDARD LVCMOS25 [get_ports IIC_MUX_RESET_B]

# SI5324 Low Jitter Clock - GT REFCLK
create_clock -period 5.0 [get_ports REC_CLOCK_C_P]

set_property PACKAGE_PIN W28 [get_ports REC_CLOCK_C_N]
set_property IOSTANDARD LVCMOS25 [get_ports REC_CLOCK_C_N]
set_property PACKAGE_PIN W27 [get_ports REC_CLOCK_C_P]
set_property IOSTANDARD LVCMOS25 [get_ports REC_CLOCK_C_P]

set_property PACKAGE_PIN AG24 [get_ports SI5326_INT_ALM_LS]
set_property IOSTANDARD LVCMOS25 [get_ports SI5326_INT_ALM_LS]
set_property PACKAGE_PIN L8 [get_ports SI5326_OUT_C_P]
set_property PACKAGE_PIN L7 [get_ports SI5326_OUT_C_N]
set_property PACKAGE_PIN AE20 [get_ports SI5326_RST_LS]
set_property IOSTANDARD LVCMOS25 [get_ports SI5326_RST_LS]

# GPIO PUSHBUTTON SW
set_property PACKAGE_PIN G12 [get_ports GPIO_SW_C]
set_property IOSTANDARD LVCMOS15 [get_ports GPIO_SW_C]
set_property PACKAGE_PIN AG5 [get_ports GPIO_SW_E]
set_property IOSTANDARD LVCMOS15 [get_ports GPIO_SW_E]
set_property PACKAGE_PIN AA12 [get_ports GPIO_SW_N]
set_property IOSTANDARD LVCMOS15 [get_ports GPIO_SW_N]
#set_property PACKAGE_PIN AB12 [get_ports GPIO_SW_S]
#set_property IOSTANDARD LVCMOS15 [get_ports GPIO_SW_S]
#set_property PACKAGE_PIN AC6 [get_ports GPIO_SW_W]
#set_property IOSTANDARD LVCMOS15 [get_ports GPIO_SW_W]
#set_property PACKAGE_PIN AB7 [get_ports CPU_RESET]
#set_property IOSTANDARD LVCMOS15 [get_ports CPU_RESET]

# GPIO LEDs
set_property PACKAGE_PIN AB8 [get_ports GPIO_LED_0_LS]
set_property IOSTANDARD LVCMOS15 [get_ports GPIO_LED_0_LS]
set_property PACKAGE_PIN AA8 [get_ports GPIO_LED_1_LS]
set_property IOSTANDARD LVCMOS15 [get_ports GPIO_LED_1_LS]
set_property PACKAGE_PIN AC9 [get_ports GPIO_LED_2_LS]
set_property IOSTANDARD LVCMOS15 [get_ports GPIO_LED_2_LS]
set_property PACKAGE_PIN AB9 [get_ports GPIO_LED_3_LS]
set_property IOSTANDARD LVCMOS15 [get_ports GPIO_LED_3_LS]
set_property PACKAGE_PIN AE26 [get_ports GPIO_LED_4_LS]
set_property IOSTANDARD LVCMOS25 [get_ports GPIO_LED_4_LS]
set_property PACKAGE_PIN G19 [get_ports GPIO_LED_5_LS]
set_property IOSTANDARD LVCMOS25 [get_ports GPIO_LED_5_LS]
#set_property PACKAGE_PIN E18 [get_ports GPIO_LED_6_LS]
#set_property IOSTANDARD LVCMOS25 [get_ports GPIO_LED_6_LS]
#set_property PACKAGE_PIN F16 [get_ports GPIO_LED_7_LS]
#set_property IOSTANDARD LVCMOS25 [get_ports GPIO_LED_7_LS]

set_property PULLUP true [get_ports IIC_SDA_MAIN]
set_property PULLUP true [get_ports IIC_SCL_MAIN]

set_false_path -from [get_pins config_done_reg/C] -to [get_pins gt_soft_reset_r_reg/D]
