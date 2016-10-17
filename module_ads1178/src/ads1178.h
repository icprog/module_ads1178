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
