/**
 * Module:  module_usb_aud_shared
 * Version: 2v1
 * Build:   16d27b9745fbee4dd7f17ad8d31813326cea9187
 * File:    audioports.xc
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2010
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
#include <xs1.h>
#include "devicedefines.h"
#include "audioports.h"

/* Audio IOs */

#if (I2S_CHANS_DAC != 0)
extern buffered out port:32 p_i2s_dac[I2S_WIRES_DAC];
#endif

#if (I2S_CHANS_ADC != 0)
extern buffered in port:32  p_i2s_adc[I2S_WIRES_ADC];
#endif

#if (I2S_CHANS_DAC != 0) || (I2S_CHANS_ADC != 0)
#ifdef CODEC_SLAVE
extern buffered out port:32 p_lrclk;
extern buffered out port:32 p_bclk;
#else
extern in port p_lrclk;
extern in port p_bclk;
#endif
#endif

extern port p_mclk;

extern clock    clk_audio_mclk;
extern clock    clk_audio_bclk;

void ConfigAudioPorts(unsigned int divide) 
{

#ifdef CODEC_SLAVE
    /* Output 0 on BCLK to ensure clock is low
     * Required as stop_clock will only complete when the clock is low
     */
    configure_out_port_no_ready(p_bclk, clk_audio_mclk, 0);
    p_bclk <: 0;

    /* Stop bit and master clock blocks and clear port buffers */
    stop_clock(clk_audio_bclk);
    stop_clock(clk_audio_mclk);

    clearbuf(p_lrclk);
    clearbuf(p_bclk);

#if (I2S_CHANS_ADC != 0)
    for(int i = 0; i < I2S_WIRES_ADC; i++)
    {
        clearbuf(p_i2s_adc[i]);
    }
#endif

#if (I2S_CHANS_DAC != 0)
    for(int i = 0; i < I2S_WIRES_DAC; i++)
    {
        clearbuf(p_i2s_dac[i]);
    }
#endif

    /* Clock master clock-block from master-clock port */
    configure_clock_src(clk_audio_mclk, p_mclk);

    /* For a divide of one (i.e. bitclock == master-clock) BClk is set to clock_output mode.
     * In this mode it outputs an edge clock on every tick of itsassociated clock_block.
     *
     * For all other divides, BClk is clocked by the master clock and data
     * will be output to p_bclk to generate the bit clock.
     */
    if (divide == 1) /* e.g. 176.4KHz from 11.2896 */
    {
        configure_port_clock_output(p_bclk, clk_audio_mclk);
    }
    else
    {
        /* bit clock port from master clock clock-clock block */
        configure_out_port_no_ready(p_bclk, clk_audio_mclk, 0);
    }

    /* Generate bit clock block from pin */
    configure_clock_src(clk_audio_bclk, p_bclk);


#if (I2S_CHANS_DAC != 0)
    /* Clock I2S output data ports from clock block */
    for(int i = 0; i < I2S_WIRES_DAC; i++)
    {
        configure_out_port_no_ready(p_i2s_dac[i], clk_audio_bclk, 0);
    }
#endif

#if (I2S_CHANS_ADC != 0)
    /* Clock I2S input data ports from clock block */
    for(int i = 0; i < I2S_WIRES_ADC; i++)
    {
        configure_in_port_no_ready(p_i2s_adc[i], clk_audio_bclk);
    }
#endif

    /* Clock LR clock from bit clock-block */
    configure_out_port_no_ready(p_lrclk, clk_audio_bclk, 0);

    /* Start clock blocks ticking */
    start_clock(clk_audio_mclk);
    start_clock(clk_audio_bclk);

    /* bclk initial state needs to be high  */
    p_bclk <: 0xFFFFFFFF;

    /* Pause until output completes */
    sync(p_bclk);

#else
    /* Stop bit and master clock blocks and clear port buffers */
    stop_clock(clk_audio_bclk);
    stop_clock(clk_audio_mclk);

    /* Clock bclk clock-block from bclk pin */
    configure_clock_src(clk_audio_bclk, p_bclk);

     /* Clock I2S output data ports from b-clock clock block */
    for(int i = 0; i < I2S_WIRES_DAC; i++)
    {
        configure_out_port_no_ready(p_i2s_dac[i], clk_audio_bclk, 0);
    }

    /* Clock I2S input data ports from clock block */
    for(int i = 0; i < I2S_WIRES_ADC; i++)
    {
        configure_in_port_no_ready(p_i2s_adc[i], clk_audio_bclk);
    }

    configure_in_port_no_ready(p_lrclk, clk_audio_bclk);

    start_clock(clk_audio_bclk);

#endif
}
