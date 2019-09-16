# ESP32-SPIディスプレイ出力（ST7735モード）

グラフィックライブラリとして、LittlevGLを使用する。
uGFX等と比較すると、ライセンスが緩いためホビー用途～小ロット生産ならLittlevGL一択。
LittlevGLのSPIドライバとして、下位レイヤーでTFT_eSPIを使用しているため、
最初にTFT_eSPIを導入する必要がある。

### リンク
 - LittlevGL： https://littlevgl.com/
 - LittlevGL Arduino： https://github.com/littlevgl/lv_arduino
 - TFT_eSPI： https://github.com/Bodmer/TFT_eSPI


# TFT_eSPIの導入
Arduinoのライブラリマネージャーから「TFT_eSPI」をインストールする。

「C:\Users\<USER>\Documents\Arduino\libraries\TFT_eSPI」にインストールされる。

フォルダ内の「User_Setup.h」を編集してディスプレイの設定を変更する。

## ドライバの種類変更（デフォILI9341→ST7735）
 - 19行目「#define ILI9341_DRIVER」→コメントアウト「//#define ILI9341_DRIVER」
 - 20行目「//#define ST7735_DRIVER」→コメントアウト解除「#define ST7735_DRIVER」

## 解像度設定
「C:\Users\<USER>\Documents\Arduino\libraries\TFT_eSPI\User_Setup.h」

57行目に追記
 - #define TFT_WIDTH 480
 - #define TFT_HEIGHT 272

解像度270モードのときは270で。


## ピン番号の設定をする。

### VSPIを使用する場合
SPI使用時にデフォルトで使用されるのがVSPI。SDライブラリもVSPIがデフォ。

 - 161行目「//#define TFT_MISO 19」→コメントアウト解除「#define TFT_MISO -1」
 - 162行目「//#define TFT_MOSI 23」→コメントアウト解除「#define TFT_MOSI 23」
 - 163行目「//#define TFT_SCLK 18」→コメントアウト解除「#define TFT_SCLK 18」
 - 164行目「//#define TFT_CS   15」→コメントアウト解除・数値変更「#define TFT_CS   5」
 - 165行目「//#define TFT_DC    2」→コメントアウト解除・数値変更「#define TFT_DC    17」
 - 166行目「//#define TFT_RST   4」→コメントアウト解除・数値変更「#define TFT_RST   16」

デフォルトピン配置。GPIOマトリクスがあるため、任意の番号に変更可能。


### HSPIを使用する場合
SDカード等でVSPIを使用する場合に、ディスプレイをHSPIに逃がす。


 - 161行目「//#define TFT_MISO 19」→コメントアウト解除・数値変更「#define TFT_MISO -1」
 - 162行目「//#define TFT_MOSI 23」→コメントアウト解除・数値変更「#define TFT_MOSI 13」
 - 163行目「//#define TFT_SCLK 18」→コメントアウト解除・数値変更「#define TFT_SCLK 14」
 - 164行目「//#define TFT_CS   15」→コメントアウト解除「#define TFT_CS   15」
 - 165行目「//#define TFT_DC    2」→コメントアウト解除・数値変更「#define TFT_DC    17」
 - 166行目「//#define TFT_RST   4」→コメントアウト解除・数値変更「#define TFT_RST   16」
デフォルトピン配置。GPIOマトリクスがあるため、任意の番号に変更可能。

 - 269行目「//#define USE_HSPI_PORT」→コメントアウト解除「#define USE_HSPI_PORT」


※なお、現在の設定を確認するのに、Arduino上で「ファイル」→「スケッチ例」→「TFT_eSPI」→「Test and diagnostics」→「Read_User_Setup」を書き込み実行すると、シリアルモニタ（115200bps）に現在のTFT_eSPIの設定内容が表示される。



# LittlevGL導入

Arduinoのライブラリマネージャーから「LittlevGL」をインストールする。

「C:\Users\<USER>\Documents\Arduino\libraries\LittlevGL」にインストールされる。

フォルダ内の「lv_conf.h」を編集してディスプレイの設定を変更する。

「C:\Users\<USER>\Documents\Arduino\libraries\LittlevGL\lv_conf.h」

23行目の解像度変更
 - #define LV_HOR_RES_MAX          (320)
 - #define LV_VER_RES_MAX          (240)
↓
 - #define LV_HOR_RES_MAX          (480)
 - #define LV_VER_RES_MAX          (272)



サンプルコードを試す。
Arduino上で「ファイル」→「スケッチ例」→「LittlevGL」→「ESP32_TFT_eSPI」

80行目の解像度指定部分を書き換える。
 -  disp_drv.hor_res = 480;
 -  disp_drv.ver_res = 272;

画面表示されるはず。


