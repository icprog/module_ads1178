
#ifdef HARTING_A1
	#define ADC_TILE 1 						/* Tile to which the ADC pins are connected to*/
	#define ADC_CLK XS1_PORT_1A 			/* Clock output for the ADC operation */
	
	#define ADC_SPI_MISO_8PORT XS1_PORT_8A 	/* 8 Bit input port for the 8 SPI outputs of the chip */ 
	#define ADC_SPI_SCLK XS1_PORT_1B 		/* SPI clock output */
	#define ADC_SPI_MOSI XS1_PORT_1C 		/* Master out port */
	
	#define ADC_POWER_DOWN XS1_PORT_1D 		/* Power disable output */
	
	#define ADC_FRM0 XS1_PORT_1E 			/* Output format mode */
	#define ADC_FRM1 XS1_PORT_1F 			/* Output format mode */
	#define ADC_FRM2 XS1_PORT_1J 			/* Output format mode */
	
	#define ADC_CLKDIV XS1_PORT_1G 			/* Clock divider */
	
	#define ADC_MODE XS1_PORT_1H 			/* 0 high speed / 1 low power */
	
	#define ADC_SYNC XS1_PORT_1I 			/* Syncronisation input (restarts all channels) */
	
	#define ADC_DRDY_FSYNC XS1_PORT_1N 		/* Data Ready in SPI / Frame Sync in Frame mode */
	

#else
	#error not supported yet
#endif