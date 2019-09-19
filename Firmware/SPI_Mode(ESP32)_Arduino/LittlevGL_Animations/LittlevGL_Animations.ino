#include <lvgl.h>
#include <Ticker.h>
#include <TFT_eSPI.h>

#define LVGL_TICK_PERIOD 20

Ticker tick; /* timer for interrupt handler */

TFT_eSPI tft = TFT_eSPI(); /* TFT instance */
static lv_disp_buf_t disp_buf;
static lv_color_t buf[LV_HOR_RES_MAX * 10];

lv_style_t btn3_style;

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

  /*Create a button the demonstrate built-in animations*/
  lv_obj_t * btn1;
  btn1 = lv_btn_create(scr, NULL);
  lv_obj_set_pos(btn1, 10, 10);     /*Set a position. It will be the animation's destination*/
  lv_obj_set_size(btn1, 80, 50);

  label = lv_label_create(btn1, NULL);
  lv_label_set_text(label, "Float");

  /* Float in the button using a built-in function
   * Delay the animation with 2000 ms and float in 300 ms. NULL means no end callback*/
  lv_anim_t a;
  a.var = btn1;
  a.start = -lv_obj_get_height(btn1);
  a.end = lv_obj_get_y(btn1);
  a.exec_cb = (lv_anim_exec_xcb_t)lv_obj_set_y;
  a.path_cb = lv_anim_path_linear;
  a.ready_cb = NULL;
  a.act_time = -2000; /*Delay the animation*/
  a.time = 300;
  a.playback = 0;
  a.playback_pause = 0;
  a.repeat = 0;
  a.repeat_pause = 0;
  a.user_data = NULL;
  lv_anim_create(&a);

  /*Create a button to demonstrate user defined animations*/
  lv_obj_t * btn2;
  btn2 = lv_btn_create(scr, NULL);
  lv_obj_set_pos(btn2, 10, 80);     /*Set a position. It will be the animation's destination*/
  lv_obj_set_size(btn2, 80, 50);

  label = lv_label_create(btn2, NULL);
  lv_label_set_text(label, "Move");

  /*Create an animation to move the button continuously left to right*/
  a.var = btn2;
  a.start = lv_obj_get_x(btn2);
  a.end = a.start + (100);
  a.exec_cb = (lv_anim_exec_xcb_t)lv_obj_set_x;
  a.path_cb = lv_anim_path_linear;
  a.ready_cb = NULL;
  a.act_time = -1000;             /*Negative number to set a delay*/
  a.time = 400;                 /*Animate in 400 ms*/
  a.playback = 1;               /*Make the animation backward too when it's ready*/
  a.playback_pause = 0;             /*Wait before playback*/
  a.repeat = 1;                 /*Repeat the animation*/
  a.repeat_pause = 500;             /*Wait before repeat*/
  lv_anim_create(&a);

  /*Create a button to demonstrate the style animations*/
  lv_obj_t * btn3;
  btn3 = lv_btn_create(scr, NULL);
  lv_obj_set_pos(btn3, 10, 150);     /*Set a position. It will be the animation's destination*/
  lv_obj_set_size(btn3, 80, 50);

  label = lv_label_create(btn3, NULL);
  lv_label_set_text(label, "Style");

  /*Create a unique style for the button*/
  lv_style_copy(&btn3_style, lv_btn_get_style(btn3, LV_BTN_STYLE_REL));
  lv_btn_set_style(btn3, LV_BTN_STATE_REL, &btn3_style);

  /*Animate the new style*/
  lv_anim_t sa;
  lv_style_anim_init(&sa);
  lv_style_anim_set_styles(&sa, &btn3_style, &lv_style_btn_rel, &lv_style_pretty);
  lv_style_anim_set_time(&sa, 500, 500);
  lv_style_anim_set_playback(&sa, 500);
  lv_style_anim_set_repeat(&sa, 500);
  lv_style_anim_create(&sa);
  
}


void loop() {

  lv_task_handler(); /* let the GUI do its work */
  delay(5);
}
