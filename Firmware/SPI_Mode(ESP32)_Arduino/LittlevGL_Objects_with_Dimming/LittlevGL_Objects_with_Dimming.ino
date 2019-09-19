#include <lvgl.h>
#include <Ticker.h>
#include <TFT_eSPI.h>

#define LVGL_TICK_PERIOD 20

Ticker tick; /* timer for interrupt handler */
Ticker slider_inc;
uint8_t slider_value = 0;

TFT_eSPI tft = TFT_eSPI(); /* TFT instance */
static lv_disp_buf_t disp_buf;
static lv_color_t buf[LV_HOR_RES_MAX * 10];

static lv_obj_t * slider;

void slider_increment() {
  slider_value = slider_value + 1;
  if (slider_value > 100) {
    slider_value = 0;
  }
  lv_slider_set_value(slider, slider_value, false);
}


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

  // ########## Backlight Dimming ##########
  tft.writecommand(0x02);
  tft.writedata(map(slider_value, 0, 100, 0, 255));
  // ########## Backlight Dimming ##########

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

  /* Create simple label */
  lv_obj_t *label = lv_label_create(lv_scr_act(), NULL);
  lv_label_set_text(label, "Object usage demo");
  lv_obj_set_x(label, 50);
  lv_obj_set_y(label, 10);

  lv_obj_t * btn1 = lv_btn_create(lv_disp_get_scr_act(NULL), NULL);
  //lv_obj_set_event_cb(btn1, btn_event_cb);
  lv_obj_set_pos(btn1, 350, 10);
  label = lv_label_create(btn1, NULL);
  lv_label_set_text(label, "Button 1");

  lv_obj_t * btn2 = lv_btn_create(lv_scr_act(), btn1);
  lv_obj_align(btn2, btn1, LV_ALIGN_OUT_BOTTOM_LEFT, 0, 20);
  label = lv_label_create(btn2, NULL);
  lv_label_set_text(label, "Button 2");

  
  lv_obj_t * btn3 = lv_btn_create(lv_scr_act(), btn1);
  lv_obj_align(btn3, btn2, LV_ALIGN_OUT_BOTTOM_LEFT, 0, 20);
  label = lv_label_create(btn3, NULL);
  lv_label_set_text(label, "Button 3");

  slider = lv_slider_create(lv_scr_act(), NULL);
  lv_obj_set_size(slider, lv_obj_get_width(lv_scr_act())  / 3, LV_DPI / 3);
  lv_obj_set_x(slider, 50);
  lv_obj_set_y(slider, 60);
  lv_slider_set_value(slider, slider_value, false);

  lv_obj_t * ddlist = lv_ddlist_create(lv_scr_act(), NULL);
  lv_obj_align(ddlist, slider, LV_ALIGN_OUT_RIGHT_TOP, 50, 0);
  lv_obj_set_top(ddlist, true);
  lv_ddlist_set_options(ddlist, "None\nLittle\nHalf\nA lot\nAll");
  //lv_obj_set_event_cb(ddlist, ddlist_event_cb);

  lv_obj_t * chart = lv_chart_create(lv_scr_act(), NULL);
  lv_obj_set_size(chart, lv_obj_get_width(lv_scr_act()) / 2, lv_obj_get_width(lv_scr_act()) / 4);
  lv_obj_align(chart, slider, LV_ALIGN_OUT_BOTTOM_LEFT, 0, 40);
  lv_chart_set_series_width(chart, 3);

  lv_chart_series_t * dl1 = lv_chart_add_series(chart, LV_COLOR_RED);
  lv_chart_set_next(chart, dl1, 10);
  lv_chart_set_next(chart, dl1, 25);
  lv_chart_set_next(chart, dl1, 45);
  lv_chart_set_next(chart, dl1, 80);

  lv_chart_series_t * dl2 = lv_chart_add_series(chart, lv_color_make(0x40, 0x70, 0xC0));
  lv_chart_set_next(chart, dl2, 10);
  lv_chart_set_next(chart, dl2, 25);
  lv_chart_set_next(chart, dl2, 45);
  lv_chart_set_next(chart, dl2, 80);
  lv_chart_set_next(chart, dl2, 75);
  lv_chart_set_next(chart, dl2, 505);

  slider_inc.attach_ms(100, slider_increment);
  
}


void loop() {

  lv_task_handler(); /* let the GUI do its work */
  delay(5);
}
