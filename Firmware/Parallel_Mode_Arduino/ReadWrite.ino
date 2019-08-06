/*
   SD card read/write

   This example shows how to read and write data to and from an SD card file
   The circuit:
 * SD card attached to SPI bus as follows:
 ** MOSI - pin 11
 ** MISO - pin 12
 ** CLK - pin 13
 ** CS - pin 4

 created   Nov 2010
 by David A. Mellis
 modified 9 Apr 2012
 by Tom Igoe

 This example code is in the public domain.

 */

#include <SPI.h>
#include <SD.h>
             //LSB                 MSB
int rPin[8] = { 2, 3, 4, 5, 6, 7, 8, 9};
int gPin[8] = {10,11,12,13,22,23,24,25};
int bPin[8] = {26,27,28,29,30,31,32,33};
                 //LSB                                            MSB
int addrPin[17] = {34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50};

File myFile;

void setDigitalPins(int* pin,int data,int length){
	for(int i = 0; i < length; i++){
		if((data & (1 << i)) == 0){
			digitalWrite(pin[i],LOW);
		}else{
			digitalWrite(pin[i],HIGH);
		}
	}
}

void setup() {

  for(int i = 0; i < 8; i++){
    pinMode(rPin[i],OUTPUT);
  }

  for(int i = 0; i < 8; i++){
    pinMode(gPin[i],OUTPUT);
  }

  for(int i = 0; i < 8; i++){
    pinMode(bPin[i],OUTPUT);
  }

  for(int i = 0; i < 17; i++){
    pinMode(addrPin[i],OUTPUT);
  }

  pinMode(51,OUTPUT);


	// Open serial communications and wait for port to open:
	Serial.begin(9600);
	while (!Serial) {
		; // wait for serial port to connect. Needed for native USB port only
	}


	Serial.print("Initializing SD card...");

	if (!SD.begin(4)) {
		Serial.println("initialization failed!");
		return;
	}
	Serial.println("initialization done.");

	// re-open the file for reading:
	myFile = SD.open("data.txt");
	if (myFile) {
		Serial.println("data.txt:");

		char colorInput[6];

		int r;
		int g;
		int b;

    int currentAddr = 0;
		while(myFile.available()){
      //Serial.println(currentAddr);
      
				for(int i = 0; i < 6; i++){
        char tmp = myFile.read();
          //Serial.print(tmp);
					colorInput[i] = tmp;
				}
       //Serial.println(colorInput);

        char *tmp = colorInput;
				int number = strtol( tmp, NULL, 16);

				// Split them up into r, g, b values
				int r = number >> 16;
				int g = number >> 8 & 0xFF;
				int b = number & 0xFF;

				setDigitalPins(rPin,r,8);
				setDigitalPins(gPin,g,8);
				setDigitalPins(bPin,b,8);

				setDigitalPins(addrPin,currentAddr,17);

				digitalWrite(51,HIGH);
        digitalWrite(51,LOW);

       currentAddr++;
		}
    digitalWrite(51,LOW);
		// close the file:
    setDigitalPins(addrPin,0b11111111111111111,17);
    digitalWrite(51,HIGH);
    delayMicroseconds(1);
    digitalWrite(51,LOW);
		myFile.close();
		Serial.println("finish!");
	} else {
		// if the file didn't open, print an error:
		Serial.println("error opening test.txt");
	}
}

void loop() {
	// nothing happens after setup
}


