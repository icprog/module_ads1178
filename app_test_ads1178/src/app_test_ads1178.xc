/*
 * app_test_ads1178.xc
 *
 *  Created on: Oct 11, 2016
 *      Author: cyborg-x1
 */

#define HARTING_A1

#include <xs1.h>
#include <spi.h>
#include <platform.h>
#include <ads1178.h>
#include "harting_bsp.inc"
#include <stdio.h>
#include <xscope.h>


void xscope_user_init(void) {
  xscope_register(0, 0, "", 0, "");
  xscope_config_io(XSCOPE_IO_BASIC);
}


#ifdef HARTING_A1

    //Hardwire stuff - to what? see below...
    on tile[ADC_TILE]: out port p_adc_spi_mosi = ADC_SPI_MOSI;
    on tile[ADC_TILE]: out port p_adc_frm0 = ADC_FRM0;
    on tile[ADC_TILE]: out port p_adc_frm1 = ADC_FRM1;
    on tile[ADC_TILE]: out port p_adc_frm2 = ADC_FRM2;
    on tile[ADC_TILE]: out port p_adc_clkdiv = ADC_CLKDIV;
    on tile[ADC_TILE]: out port p_adc_mode = ADC_MODE;


    //    on tile[ADC_TILE]: buffered in port:32  p_adc_spi_miso8 = ADC_SPI_MISO_8PORT;
    //    on tile[ADC_TILE]: out buffered port:32 p_adc_spi_sclk = ADC_SPI_SCLK,
    //    on tile[ADC_TILE]: out port p_adc_clk      = ADC_CLK;
    //    on tile[ADC_TILE]: out port p_adc_sync = ADC_SYNC;
    //    on tile[ADC_TILE]: out port p_adc_drdy = ADC_DRDY_FSYNC;
    //    on tile[ADC_TILE]: out port p_adc_pwrdwn = ADC_POWER_DOWN;

        on tile[ADC_TILE]:ads1178_settings adc_settings=
        {
                ADC_SPI_MISO_8PORT,
                ADC_SPI_SCLK,
                ADC_SYNC,
                ADC_DRDY_FSYNC,
                ADC_POWER_DOWN,
                ADC_CLK,
                {XS1_CLKBLK_1,XS1_CLKBLK_2,XS1_CLKBLK_3},
                1,
                100000000 /* 100 MHz */
        };




#else
    #error NOT SUPPORTED YET
#endif



void main_ctrl(client interface adc_ads1178_if adc_if)
{

    printf("Start!\n");
    unsigned i=0;
    while(1);
    {
        i++;
        xscope_int(CHANNEL0, i);
    }


    {
        select
        {
        case adc_if.data_ready():
          ads1178_data_t x = adc_if.get_data();

          xscope_int(CHANNEL0, x.ch[0]);
          xscope_int(CHANNEL1, x.ch[1]);
          xscope_int(CHANNEL2, x.ch[2]);
          xscope_int(CHANNEL3, x.ch[3]);
          xscope_int(CHANNEL4, x.ch[4]);
          xscope_int(CHANNEL5, x.ch[5]);
          xscope_int(CHANNEL6, x.ch[6]);
          xscope_int(CHANNEL7, x.ch[7]);
          break;

        }
    }
}


int main()
{

    adc_ads1178_if adc_if;

    par
    {
        on tile[ADC_TILE]:
        {
#ifdef HARTING_A1
            //TODO HARDWIRE:
            p_adc_spi_mosi<:0;

            //Set to SPI mode >Discrete< using all output lines
            p_adc_frm2<:0;
            p_adc_frm1<:1;
            p_adc_frm0<:0;

            //Clk div to 0 - high speed mode max daisy channels 16 - we have 8 so we can save some power
            p_adc_clkdiv<:0;

            //Mode highspeed
            p_adc_mode<:0;
#else
    #error Unsupported - remove error and put settings accordingly
#endif

            //Service of adc
            //ads1178_service(adc_if,adc_settings);
        }

        on tile[ADC_TILE]:
        main_ctrl( adc_if);

    }


    return 0;
}
