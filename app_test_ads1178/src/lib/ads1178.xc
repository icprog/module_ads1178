#include "ads1178.h"
#include <xclib.h>


void clockGenerator(out port p_clk, unsigned sysclk, unsigned edge_time)
{
    timer tmr;
    unsigned time;

    tmr:>time;
    unsigned currentEdge=0;
    p_clk<:currentEdge;

    while(1)
    {
        select
        {
            case tmr when timerafter(time+edge_time):> time:
                currentEdge=!currentEdge;
                p_clk<:currentEdge;
            break;
        }
    }
}



static void spi_setup(
        in buffered port:32 miso,
        out buffered port:32 sclk,
        clock cb0,
        clock cb1,
        spi_mode_t mode,
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

    //fiddle the data out of the stream
    for (int ch= 0; ch < 8; ++ch)
    {
        for (int bit = 0; bit < 16; ++bit)
        {
            //get in which raw variable the bit is stored
            uint32_t cur_raw=raw_in[3-bit/4];


            //Get the place of the current bit inside the raw variable
            uint8_t place=((bit*8)%32)+ch;

            //get truth value of current bit and shift to right place
            data.ch[ch]|=(!!(cur_raw&(1<<place)))<<(bit);

        }
    }

}

typedef enum
{
    ADC_STOP,
    ADC_SINGLE,
    ADC_CONTINOUS,
}adc_mode_t;



void ads1178_service(server interface adc_ads1178_if i_ctrl, ads1178_settings& settings)
{
#ifdef CLKBLKTHING
    stop_clock(settings.c_clk[2]);
    unsigned d = (settings.systemClock + 4*27000 - 1)/(4*27000);
    configure_clock_ref(settings.c_clk[2], d);
    configure_port_clock_output(settings.p_adc_clk, settings.c_clk[2]);
    start_clock(settings.c_clk[2]);
#endif


    par
    {
#ifndef CLKBLKTHING
        clockGenerator(settings.p_adc_clk, settings.systemClock, 27);
#endif

        {//MainService
            spi_setup(settings.p_adc_spi_miso8,
                      settings.p_adc_spi_sclk,
                      settings.c_clk[0],
                      settings.c_clk[1],
                      SPI_MODE_0,
                      100000/4 //TODO test more
                      );



            settings.p_adc_pwrdwn<:settings.startPoweredUp;
            settings.p_adc_sync<:1;
            unsigned drdy_state;
            settings.p_adc_drdy:>drdy_state;
            ads1178_data_t data;
            while(1)
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


                case  settings.p_adc_drdy when pinseq(drdy_state) :> drdy_state:
                        if(drdy_state)
                        {
                            spi_transfer(settings.p_adc_spi_miso8,settings.p_adc_spi_sclk,data);
                            i_ctrl.data_ready();
                        }
                    break;

            }
        }//end MainService
    }
}
