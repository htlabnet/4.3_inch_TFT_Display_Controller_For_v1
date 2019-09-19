#include <lvgl.h>
#include <Ticker.h>
#include <TFT_eSPI.h>

#define LVGL_TICK_PERIOD 20

Ticker tick; /* timer for interrupt handler */

TFT_eSPI tft = TFT_eSPI(); /* TFT instance */
static lv_disp_buf_t disp_buf;
static lv_color_t buf[LV_HOR_RES_MAX * 10];

#if USE_LV_LOG != 0
/* Serial debugging */
void my_print(lv_log_level_t level, const char * file, uint32_t line, const char * dsc)
{

  Serial.printf("%s@%d->%s\r\n", file, line, dsc);
  delay(100);
}
#endif

/* Display flushing */
void my_disp_flush(lv_disp_drv_t *disp, const lv_area_t *area, lv_color_t *color_p)
{
  uint16_t c;

  tft.startWrite(); /* Start new TFT transaction */
  tft.setAddrWindow(area->x1, area->y1, (area->x2 - area->x1 + 1), (area->y2 - area->y1 + 1)); /* set the working window */
  for (int y = area->y1; y <= area->y2; y++) {
    for (int x = area->x1; x <= area->x2; x++) {
      c = color_p->full;
      tft.writeColor(c, 1);
      color_p++;
    }
  }
  tft.endWrite(); /* terminate TFT transaction */
  lv_disp_flush_ready(disp); /* tell lvgl that flushing is done */
}

/* Interrupt driven periodic handler */
static void lv_tick_handler(void)
{

  lv_tick_inc(LVGL_TICK_PERIOD);
}

/* Reading input device (simulated encoder here) */
bool read_encoder(lv_indev_drv_t * indev, lv_indev_data_t * data)
{
  static int32_t last_diff = 0;
  int32_t diff = 0; /* Dummy - no movement */
  int btn_state = LV_INDEV_STATE_REL; /* Dummy - no press */

  data->enc_diff = diff - last_diff;;
  data->state = btn_state;

  last_diff = diff;

  return false;
}

void setup() {

  Serial.begin(115200); /* prepare for possible serial debug */

  lv_init();

#if USE_LV_LOG != 0
  lv_log_register_print(my_print); /* register print function for debugging */
#endif

  tft.begin(); /* TFT init */
  tft.setRotation(0); /* Landscape orientation */

  lv_disp_buf_init(&disp_buf, buf, NULL, LV_HOR_RES_MAX * 10);

  /*Initialize the display*/
  lv_disp_drv_t disp_drv;
  lv_disp_drv_init(&disp_drv);
  disp_drv.hor_res = 480;
  disp_drv.ver_res = 272;
  disp_drv.flush_cb = my_disp_flush;
  disp_drv.buffer = &disp_buf;
  lv_disp_drv_register(&disp_drv);


  /*Initialize the touch pad*/
  lv_indev_drv_t indev_drv;
  lv_indev_drv_init(&indev_drv);
  indev_drv.type = LV_INDEV_TYPE_ENCODER;
  indev_drv.read_cb = read_encoder;
  lv_indev_drv_register(&indev_drv);

  /*Initialize the graphics library's tick*/
  tick.attach_ms(LVGL_TICK_PERIOD, lv_tick_handler);

  lv_obj_t * scr = lv_disp_get_scr_act(NULL);   /*Get the current screen*/

  lv_obj_t * label;

  /*LV_DPI*/
  lv_obj_t * btn1;
  btn1 = lv_btn_create(scr, NULL);
  lv_obj_set_pos(btn1, LV_DPI / 10, LV_DPI / 10);   /*Use LV_DPI to set the position*/
  lv_obj_set_size(btn1, LV_DPI, LV_DPI / 2);      /*Use LVDOI to set the size*/

  label = lv_label_create(btn1, NULL);
  lv_label_set_text(label, "LV_DPI");

  /*ALIGN*/
  lv_obj_t * btn2;
  btn2 = lv_btn_create(scr, btn1);
  lv_obj_align(btn2, btn1, LV_ALIGN_OUT_RIGHT_MID, LV_DPI / 4, 0);

  label = lv_label_create(btn2, NULL);
  lv_label_set_text(label, "Align");

  /*AUTO FIT*/
  lv_obj_t * btn3;
  btn3 = lv_btn_create(scr, btn1);
  lv_btn_set_fit(btn3, LV_FIT_TIGHT);

  label = lv_label_create(btn3, NULL);
  lv_label_set_text(label, "Fit");

  lv_obj_align(btn3, btn1, LV_ALIGN_OUT_BOTTOM_MID, 0, LV_DPI / 4);   /*Align when already resized because of the label*/

  /*LAYOUT*/
  lv_obj_t * btn4;
  btn4 = lv_btn_create(scr, btn1);
  lv_btn_set_fit(btn4, LV_FIT_TIGHT);       /*Enable fit too*/
  lv_btn_set_layout(btn4, LV_LAYOUT_COL_R);   /*Right aligned column layout*/

  label = lv_label_create(btn4, NULL);
  lv_label_set_text(label, "First");

  label = lv_label_create(btn4, NULL);
  lv_label_set_text(label, "Second");

  label = lv_label_create(btn4, NULL);
  lv_label_set_text(label, "Third");

  lv_obj_align(btn4, btn2, LV_ALIGN_OUT_BOTTOM_MID, 0, LV_DPI / 4);   /*Align when already resized because of the label*/

}


void loop() {

  lv_task_handler(); /* let the GUI do its work */
  delay(5);
}
