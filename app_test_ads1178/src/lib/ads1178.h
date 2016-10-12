/*
 * ads1178.h
 *
 *  Created on: Oct 11, 2016
 *      Author: cyborg-x1
 */


#ifndef ADS1178_H_
#define ADS1178_H_

#include <platform.h>
#include <xs1.h>
#include <inttypes.h>

typedef struct
{
    buffered in port:32  p_adc_spi_miso8;
    buffered out port:32  p_adc_spi_sclk;

    out port p_adc_pwrdwn;
    out port p_adc_sync;
    in port p_adc_drdy;
    out port p_adc_clk;
    clock c_clk[3];
    unsigned startPoweredUp;
    unsigned systemClock;
}ads1178_settings;

typedef struct
{
    int16_t ch[8];
}ads1178_data_t;

typedef interface adc_ads1178_if
{
    void power_up();
    void power_down();
    void sync();

    [[notification]] slave void data_ready(void);
    [[clears_notification]] ads1178_data_t get_data();
}adc_ads1178_if;

#include <spi.h>

void ads1178_service(server interface adc_ads1178_if i_ctrl,  ads1178_settings &settings );


#endif /* ADS1178_H_ */
