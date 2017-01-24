/*
 *
 * Copyright (c) 2016, Synapticon GmbH
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *
 * 1.  Redistributions of source code must retain the above copyright notice, this
 *  list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright notice,
 *  this list of conditions and the following disclaimer in the documentation
 *  and/or other materials provided with the distribution.
 * 3.  Execution of this software or parts of it exclusively takes place on hardware
 *  produced by Synapticon GmbH.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * The views and conclusions contained in the software and documentation are those
 * of the authors and should not be interpreted as representing official policies,
 * either expressed or implied, of the FreeBSD Project.
 *
 *
 */


#include "ads1178.h"
#include <xclib.h>
#include <stdio.h>

#define _MASK(B3,B2,B1,B0) (   (B0<<24) | (B1<<16) | (B2<<8) | (B3<<0) )
#define _GETBIT(VAL,BIT) ((VAL&(1<<BIT))>>BIT)

#define MASK(VAL) _MASK( _GETBIT(VAL,3) , _GETBIT(VAL,2), _GETBIT(VAL,1) ,_GETBIT(VAL,0)  )
#define MASK_CASE(VAL) case MASK(VAL): val=VAL; break;


typedef enum
{
    SPI_MODE_0,
    SPI_MODE_1,
    SPI_MODE_2,
    SPI_MODE_3
}spi_mode_ads1178_t;

static void spi_setup(
        in buffered port:32 miso,
        out buffered port:32 sclk,
        clock cb0,
        clock cb1,
        spi_mode_ads1178_t mode,
        unsigned speed_in_khz
        )
{


    stop_clock(cb0);

    configure_clock_rate(cb0,100,4);
//    configure_clock_ref(cb0, 0);
    configure_in_port(sclk, cb0);

    stop_clock(cb1);
    configure_clock_src(cb1, sclk);
    set_port_no_sample_delay(miso);
    configure_in_port(miso,  cb1);
    start_clock(cb1);

    start_clock(cb0);
    clearbuf(miso);

    switch(mode){
    case SPI_MODE_0:
        set_port_inv(sclk);
        partout(sclk,1,1);
        break;
    case SPI_MODE_1:
        set_port_no_inv(sclk);
        partout(sclk,1,0);
        break;
    case SPI_MODE_2:
        set_port_inv(sclk);
        partout(sclk,1,0);
        break;
    case SPI_MODE_3:
        set_port_no_inv(sclk);
        partout(sclk,1,1);
        break;
    }
    sync(sclk);

}


void spi_transfer_4bits(in buffered port:32 miso,
                        out buffered port:32 sclk)
{
    clearbuf(miso); //clear any remaining data in the buffer
    partout(sclk, 8, 0xaa); //1010 1010  -> do the clock... 4 cycles ... -> 32 bits
}


int16_t ads1178_processData(const ads1178_data_t raw_in, uint8_t channel)
{

    int16_t ret=0;

    for (int r = 0;r < 4; ++r)
    {
        uint32_t masked = (raw_in.adc_raw[r] & (0x01010101<<channel))>>channel;

        int8_t val;
        switch(masked)
        {
            MASK_CASE(0)
            MASK_CASE(1)
            MASK_CASE(2)
            MASK_CASE(3)
            MASK_CASE(4)
            MASK_CASE(5)
            MASK_CASE(6)
            MASK_CASE(7)
            MASK_CASE(8)
            MASK_CASE(9)
            MASK_CASE(10)
            MASK_CASE(11)
            MASK_CASE(12)
            MASK_CASE(13)
            MASK_CASE(14)
            MASK_CASE(15)
        }
        ret|=val<<((3-r)*4);
    }

    return ret;
}






void spi_transfer(
        in buffered port:32 miso,
        out buffered port:32 sclk,
        ads1178_data_t &data)
{

    //Sample data from spi
    for(size_t cur=0;cur<4;++cur)
    {
        uint32_t in_data;
        spi_transfer_4bits(miso,sclk);
        miso :> data.adc_raw[cur];
    }
}

typedef enum
{
    ADC_STOP,
    ADC_SINGLE,
    ADC_CONTINOUS,
}adc_mode_t;


#define CLKBLKTHING
void ads1178_service(server interface adc_ads1178_if i_ctrl, ads1178_settings& settings)
{
#ifdef CLKBLKTHING
    //25MHz
    stop_clock(settings.c_clk[2]);
    configure_clock_rate(settings.c_clk[2],100,8);
    configure_port_clock_output(settings.p_adc_clk, settings.c_clk[2]);
    start_clock(settings.c_clk[2]);
#endif


    par
    {
        {//MainService
            printf("SPI Setup!\n");
            spi_setup(settings.p_adc_spi_miso8,
                      settings.p_adc_spi_sclk,
                      settings.c_clk[0],
                      settings.c_clk[1],
                      SPI_MODE_1,
                      100000
                      );

            ads1178_data_t data;
            settings.p_adc_pwrdwn<:settings.startPoweredUp;
            settings.p_adc_sync<:0;
            settings.p_adc_sync<:1;
            unsigned drdy_state;
            settings.p_adc_drdy:>drdy_state;

            while(1)
            {
                select
                {
                    case i_ctrl.power_down():
                        settings.p_adc_pwrdwn<:0;
                        break;

                    case i_ctrl.power_up():
                        settings.p_adc_pwrdwn<:1;
                        break;

                    case i_ctrl.get_data() -> ads1178_data_t odata:
                            odata=data;
                        break;


                    case i_ctrl.sync():
                        settings.p_adc_sync<:0;
                        settings.p_adc_sync<:1;
                        break;


                    case  settings.p_adc_drdy when pinsneq(drdy_state) :> drdy_state:
                            if(!drdy_state)
                            {
                                spi_transfer(settings.p_adc_spi_miso8,settings.p_adc_spi_sclk,data);
                                i_ctrl.data_ready();
                            }
                        break;

                }





            }
        }//end MainService
    }
}
