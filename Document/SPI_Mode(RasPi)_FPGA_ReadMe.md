# 概要
Raspberry PiにTFT Display ControllerをSPI接続して、ディスクトップ画面を出力する方法について説明する。  
CPLDには「Firmware\SPI_Mode(RasPi)_FPGA」のpofファイルを書き込んでおく。  
RasPi2B及びRasPi3Bにて動作確認済み。

# 1. RasPiとコントローラボードの接続
以下のように接続する。
| RasPi GPIO      | コントローラボード(P4) |
|:----------------|:-------------|
| 1: 3.3V         | 29: 3V3      |
| 2: 5V           | 11: LED      |
| 6: GND          | 12: GND      |
| 19: SPI_MOSI    | 6: SPI_MOSI  |
| 23: SPI_CLK     | 4: SPI_CLK   |
| 24: SPI_CE0_N   | 2: SPI_CS    |


# 2. Raspbianのインストール
RasPiのOSにはメジャーなRaspbianを使用した。[こちら](https://www.raspberrypi.org/downloads/raspbian/)からDLできる。  
ホストマシンがLinuxであれば、適当な場所に解凍して以下コマンドでSDにコピーすればインストール完了。  
```  
# dd bs=4M if=2019-07-10-raspbian-buster-full.img of=/dev/sdX conv=fsync
```
sdXにはSDカードのデバイス名を指定する（例: sdb）。予め以下コマンドでディスク情報を確認しておくと良い。  
```  
# fdisk sdX
```
動作検証で使用したバージョンは以下のとおり。  
* FileName: 2019-07-10-raspbian-buster-full.img
* Release date: 2019-07-10
* Kernel version: 4.19

# 3. Raspbianの設定
## 3.1. 基本設定
（※詳しくは適宜ググってください）
### SSHの設定
リモートで作業出来たほうが色々と便利なので、SSH Serverを有効にしておく。  
（なお、予めSDカードのbootディレクトリ直下に"ssh"という名前の空ファイルを配置しておけば、SSH Serverが有効状態で起動するらしい。この方法だとHDMI接続のディスプレイなしでTFTディスプレイに映像を出せる）  
raspi-config  
```
5 Interfacing Options -> P2 SSH -> enable
```

### 画面設定
周囲の黒フチ表示を解除する。  
```
設定 -> Raspberry Piの設定 -> システム -> オーバースキャン　を　「無効」に  
```
画面解像度を変更する。デフォルトでは1920x1080 60Hzで無駄に高精細＆CPUパワーを食いそうなので。
```
設定 -> Raspberry Piの設定 -> システム -> 解像度　720ｘ480 60Hz 程度でお好きに  
```

### fbtftドライバの設定
SPI接続の液晶を使用するために、SPI経由で液晶ディスプレイを制御できるfbtftドライバを使用する。  
「/etc/modules」以下の行を追加してドライバモジュールを有効にする。
```
sudo vi /etc/modules
```
追記する内容
```
spi-bcm2835
flexfb
fbtft_device
```
fbtftの設定を行うため、以下の手順で「/etc/modprobe.d」直下に「fbtft.conf」を作成する。
```
$ sudo vi /etc/modprobe.d/fbtft.conf
```
記載する内容
```
options fbtft_device name=flexfb gpios=reset:27,dc:25,led:24 speed=80000000 bgr=1 fps=60 custom=1 height=272 width=480 mode=3
options flexfb setaddrwin=0 width=480 height=272 init=-1,0x11,-2,120,-1,0x36,0x70,-1,0x3A,0x05,-1,0xB2,0x0C,0x0C,0x00,0x33,0x33,-1,0xB7,0x35,-1,0xBB,0x1A,-1,0xC0,0x2C,-1,0xC2,0x01,-1,0xC3,0x0B,-1,0xC4,0x20,-1,0xC6,0x0F,-1,0xD0,0xA4,0xA1,-1,0x21,-1,0xE0,0x00,0x19,0x1E,0x0A,0x09,0x15,0x3D,0x44,0x51,0x12,0x03,0x00,0x3F,0x3F,-1,0xE1,0x00,0x18,0x1E,0x0A,0x09,0x25,0x3F,0x43,0x52,0x33,0x03,0x00,0x3F,0x3F,-1,0x29,-3
```

### SPIの有効化
raspi-config  
```
5 Interfacing Options -> P4 SPI -> enable
```
設定後再起動を行う。

### SPI液晶用フレームバッファの存在確認
ここまでの設定で「/dev/fb1」が作成されていることを確認する。

### 音声出力先を3.5mmジャックに変更
raspi-config
```
7 Advanved Options -> A4 Audio -> 1 Force 3.5mm ('headphone') jack を選択
```

## 3.2. fbcpの導入
HDMI出力用フレームバッファ（/dev/fb0）を、SPI-LCD出力用フレームバッファ（/dev/fb1）にコピーするために、fbcpを用いる。
ツールをソースからコンパイルするためにcmakeとgitをインストール
```
$ sudo apt-get update
$ sudo apt-get install cmake git
```
以下の手順でfbcpのソースを入手し、コンパイル、インストールを行う。
```
$ cd ~
$ git clone https://github.com/tasanakorn/rpi-fbcp
$ cd rpi-fbcp/
$ mkdir build
$ cd build/
$ cmake ..
$ make
$ sudo install fbcp /usr/local/bin/fbcp
```
fbcpをOS起動時に自動起動させたい場合は、「/etc/rc.local」中の「exit 0」行の直上に「fbcp &」という行を追加する。

## 3.3. 動作確認
ここまでの設定が完了すれば、以下のコマンドによりディスクトップ画面がSPI液晶に表示されるはず。
```
$ fbcp &
```


## 参考リンク
* 超ちっちゃいCS無しの激安IPS液晶にRaspberry Piから画面を出す方法。[https://www.omorodive.com/2019/08/raspberrypi-no-cs-lcd.html](https://www.omorodive.com/2019/08/raspberrypi-no-cs-lcd.html)