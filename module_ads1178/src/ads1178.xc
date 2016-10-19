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

    configure_clock_ref(cb0, 1);
    configure_in_port(sclk,  cb0);

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


    //Set the clock divider
    stop_clock(cb0);
    unsigned d = (XS1_TIMER_KHZ + 4*speed_in_khz - 1)/(4*speed_in_khz);
    configure_clock_ref(cb0, d);
    start_clock(cb0);

}


void spi_transfer_4bits(in buffered port:32 miso,
                        out buffered port:32 sclk)
{
    clearbuf(miso); //clear any remaining data in the buffer
    partout(sclk, 8, 0xaa); //1010 1010  -> do the clock... 4 cycles ... -> 32 bits
}

void spi_transfer(
        in buffered port:32 miso,
        out buffered port:32 sclk,
        ads1178_data_t &data)
{
    //Raw data storage
    uint32_t raw_in[4];

    //Init data output to zero
    for (int i = 0; i < 8; ++i) {
        data.ch[i]=0;
    }

    //Sample data from spi
    for(size_t cur=0;cur<4;++cur)
    {
        uint32_t data;
        spi_transfer_4bits(miso,sclk);
        miso :> data;
        raw_in[cur]=data;
    }
    //printf("\n");
    //fiddle the data out of the stream
    for (int r = 0; r < 4; ++r)
    {
        for (int b = 0; b < 32; ++b)
        {
                if(b/8!=0 | r>0)
                {
                    data.ch[b%8]<<=1;
                    //printf("-");
                }
                data.ch[b%8]|=!!(raw_in[r]&(1<<b));

                //if(b%8==0)
                //printf("%i", !!(raw_in[r]&(1<<b)));


        }
     //   printf("\n");
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
    configure_clock_rate(settings.c_clk[2],100,4);
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
                      100000/100 //TODO test more
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
