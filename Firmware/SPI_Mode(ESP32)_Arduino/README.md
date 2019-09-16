# ESP32-SPI�f�B�X�v���C�o�́iST7735���[�h�j

�O���t�B�b�N���C�u�����Ƃ��āALittlevGL���g�p����B
uGFX���Ɣ�r����ƁA���C�Z���X���ɂ����߃z�r�[�p�r�`�����b�g���Y�Ȃ�LittlevGL����B
LittlevGL��SPI�h���C�o�Ƃ��āA���ʃ��C���[��TFT_eSPI���g�p���Ă��邽�߁A
�ŏ���TFT_eSPI�𓱓�����K�v������B

### �����N
 - LittlevGL�F https://littlevgl.com/
 - LittlevGL Arduino�F https://github.com/littlevgl/lv_arduino
 - TFT_eSPI�F https://github.com/Bodmer/TFT_eSPI


# TFT_eSPI�̓���
Arduino�̃��C�u�����}�l�[�W���[����uTFT_eSPI�v���C���X�g�[������B

�uC:\Users\<USER>\Documents\Arduino\libraries\TFT_eSPI�v�ɃC���X�g�[�������B

�t�H���_���́uUser_Setup.h�v��ҏW���ăf�B�X�v���C�̐ݒ��ύX����B

## �h���C�o�̎�ޕύX�i�f�t�HILI9341��ST7735�j
 - 19�s�ځu#define ILI9341_DRIVER�v���R�����g�A�E�g�u//#define ILI9341_DRIVER�v
 - 20�s�ځu//#define ST7735_DRIVER�v���R�����g�A�E�g�����u#define ST7735_DRIVER�v

## �𑜓x�ݒ�
�uC:\Users\<USER>\Documents\Arduino\libraries\TFT_eSPI\User_Setup.h�v

57�s�ڂɒǋL
 - #define TFT_WIDTH 480
 - #define TFT_HEIGHT 272

�𑜓x270���[�h�̂Ƃ���270�ŁB


## �s���ԍ��̐ݒ������B

### VSPI���g�p����ꍇ
SPI�g�p���Ƀf�t�H���g�Ŏg�p�����̂�VSPI�BSD���C�u������VSPI���f�t�H�B

 - 161�s�ځu//#define TFT_MISO 19�v���R�����g�A�E�g�����u#define TFT_MISO -1�v
 - 162�s�ځu//#define TFT_MOSI 23�v���R�����g�A�E�g�����u#define TFT_MOSI 23�v
 - 163�s�ځu//#define TFT_SCLK 18�v���R�����g�A�E�g�����u#define TFT_SCLK 18�v
 - 164�s�ځu//#define TFT_CS   15�v���R�����g�A�E�g�����E���l�ύX�u#define TFT_CS   5�v
 - 165�s�ځu//#define TFT_DC    2�v���R�����g�A�E�g�����E���l�ύX�u#define TFT_DC    17�v
 - 166�s�ځu//#define TFT_RST   4�v���R�����g�A�E�g�����E���l�ύX�u#define TFT_RST   16�v

�f�t�H���g�s���z�u�BGPIO�}�g���N�X�����邽�߁A�C�ӂ̔ԍ��ɕύX�\�B


### HSPI���g�p����ꍇ
SD�J�[�h����VSPI���g�p����ꍇ�ɁA�f�B�X�v���C��HSPI�ɓ������B


 - 161�s�ځu//#define TFT_MISO 19�v���R�����g�A�E�g�����E���l�ύX�u#define TFT_MISO -1�v
 - 162�s�ځu//#define TFT_MOSI 23�v���R�����g�A�E�g�����E���l�ύX�u#define TFT_MOSI 13�v
 - 163�s�ځu//#define TFT_SCLK 18�v���R�����g�A�E�g�����E���l�ύX�u#define TFT_SCLK 14�v
 - 164�s�ځu//#define TFT_CS   15�v���R�����g�A�E�g�����u#define TFT_CS   15�v
 - 165�s�ځu//#define TFT_DC    2�v���R�����g�A�E�g�����E���l�ύX�u#define TFT_DC    17�v
 - 166�s�ځu//#define TFT_RST   4�v���R�����g�A�E�g�����E���l�ύX�u#define TFT_RST   16�v
�f�t�H���g�s���z�u�BGPIO�}�g���N�X�����邽�߁A�C�ӂ̔ԍ��ɕύX�\�B

 - 269�s�ځu//#define USE_HSPI_PORT�v���R�����g�A�E�g�����u#define USE_HSPI_PORT�v


���Ȃ��A���݂̐ݒ���m�F����̂ɁAArduino��Łu�t�@�C���v���u�X�P�b�`��v���uTFT_eSPI�v���uTest and diagnostics�v���uRead_User_Setup�v���������ݎ��s����ƁA�V���A�����j�^�i115200bps�j�Ɍ��݂�TFT_eSPI�̐ݒ���e���\�������B



# LittlevGL����

Arduino�̃��C�u�����}�l�[�W���[����uLittlevGL�v���C���X�g�[������B

�uC:\Users\<USER>\Documents\Arduino\libraries\LittlevGL�v�ɃC���X�g�[�������B

�t�H���_���́ulv_conf.h�v��ҏW���ăf�B�X�v���C�̐ݒ��ύX����B

�uC:\Users\<USER>\Documents\Arduino\libraries\LittlevGL\lv_conf.h�v

23�s�ڂ̉𑜓x�ύX
 - #define LV_HOR_RES_MAX          (320)
 - #define LV_VER_RES_MAX          (240)
��
 - #define LV_HOR_RES_MAX          (480)
 - #define LV_VER_RES_MAX          (272)



�T���v���R�[�h�������B
Arduino��Łu�t�@�C���v���u�X�P�b�`��v���uLittlevGL�v���uESP32_TFT_eSPI�v

80�s�ڂ̉𑜓x�w�蕔��������������B
 -  disp_drv.hor_res = 480;
 -  disp_drv.ver_res = 272;

��ʕ\�������͂��B


