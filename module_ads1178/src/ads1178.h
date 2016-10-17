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

/**
 * Setup struct for the ads1178 service
 */
typedef struct
{
    buffered in port:32  p_adc_spi_miso8; //!< 8 Bit port with all the miso channels connected
    buffered out port:32  p_adc_spi_sclk; //!< 1 Bit port connected to the SPI SCLK

    out port p_adc_pwrdwn; //!< 1 Bit port connected to the adc
    out port p_adc_sync; //!< 1 Bit port connected to the adc sync
    in port p_adc_drdy; //!< 1 Bit port connected to the drdy
    out port p_adc_clk; //!< 1 Bit port connected to the CLK of the ADC
    clock c_clk[3]; //!< three different clock blocks
    unsigned startPoweredUp; //!< defines if the ADC starts directly after powerup
    unsigned systemClock; //!< System clock in Hz
}ads1178_settings;

/**
 * Data struct for getting data from the ADCs interface
 */
typedef struct
{
    int16_t ch[8]; //!< Channel data
}ads1178_data_t;

typedef interface adc_ads1178_if
{
    void power_up(); //!< enables the adc with power down pin
    void power_down(); //!< disables the adc with power down pin
    void sync(); //!< resets all the adc channels, can be used to sync the adc output to something

    [[notification]] slave void data_ready(void); //!< notification that data is ready
    [[clears_notification]] ads1178_data_t get_data(); //!< read out current data
}adc_ads1178_if;


/**
 * ADS 1178 service
 * @param i_ctrl control interface to the ADC service
 * @param settings settings struct
 */
void ads1178_service(server interface adc_ads1178_if i_ctrl, ads1178_settings &settings );


#endif /* ADS1178_H_ */
