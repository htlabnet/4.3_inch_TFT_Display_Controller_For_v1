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

  lv_obj_t * scr = lv_disp_get_scr_act(NULL);     /*Get the current screen*/

  /****************************************
   * BASE OBJECT + LABEL WITH DEFAULT STYLE
   ****************************************/
  /*Create a simple objects*/
  lv_obj_t * obj1;
  obj1 = lv_obj_create(scr, NULL);
  lv_obj_set_pos(obj1, 10, 10);

  /*Add a label to the object*/
  lv_obj_t * label;
  label = lv_label_create(obj1, NULL);
  lv_label_set_text(label, "Default");
  lv_obj_align(label, NULL, LV_ALIGN_CENTER, 0, 0);

  /****************************************
   * BASE OBJECT WITH 'PRETTY COLOR' STYLE
   ****************************************/
  /*Create a simple objects*/
  lv_obj_t * obj2;
  obj2 = lv_obj_create(scr, NULL);
  lv_obj_align(obj2, obj1, LV_ALIGN_OUT_RIGHT_MID, 20, 0);    /*Align next to the previous object*/
  lv_obj_set_style(obj2, &lv_style_pretty);                   /*Set built in style*/

  /* Add a label to the object.
   * Labels by default inherit the parent's style */
  label = lv_label_create(obj2, NULL);
  lv_label_set_text(label, "Pretty\nstyle");
  lv_obj_align(label, NULL, LV_ALIGN_CENTER, 0, 0);

  /*****************************
   * BASE OBJECT WITH NEW STYLE
   *****************************/
  /* Create a new style */
  static lv_style_t style_new;                         /*Styles can't be local variables*/
  lv_style_copy(&style_new, &lv_style_pretty);         /*Copy a built-in style as a starting point*/
  style_new.body.radius = LV_RADIUS_CIRCLE;            /*Fully round corners*/
  style_new.body.main_color = LV_COLOR_WHITE;          /*White main color*/
  style_new.body.grad_color = LV_COLOR_BLUE;           /*Blue gradient color*/
  style_new.body.shadow.color = LV_COLOR_SILVER;       /*Light gray shadow color*/
  style_new.body.shadow.width = 8;                     /*8 px shadow*/
  style_new.body.border.width = 2;                     /*2 px border width*/
  style_new.text.color = LV_COLOR_RED;                 /*Red text color */
  style_new.text.letter_space = 10;                    /*10 px letter space*/

  /*Create a base object and apply the new style*/
  lv_obj_t * obj3;
  obj3 = lv_obj_create(scr, NULL);
  lv_obj_align(obj3, obj2, LV_ALIGN_OUT_RIGHT_MID, 20, 0);
  lv_obj_set_style(obj3, &style_new);

  /* Add a label to the object.
   * Labels by default inherit the parent's style */
  label = lv_label_create(obj3, NULL);
  lv_label_set_text(label, "New\nstyle");
  lv_obj_align(label, NULL, LV_ALIGN_CENTER, 0, 0);

  /************************
   * CREATE A STYLED BAR
   ***********************/
  /* Create a bar background style */
  static lv_style_t style_bar_bg;
  lv_style_copy(&style_bar_bg, &lv_style_pretty);
  style_bar_bg.body.radius = 3;
  style_bar_bg.body.opa = LV_OPA_TRANSP;                  /*Empty (not filled)*/
  style_bar_bg.body.border.color = LV_COLOR_GRAY;         /*Gray border color*/
  style_bar_bg.body.border.width = 6;                     /*2 px border width*/
  style_bar_bg.body.border.opa = LV_OPA_COVER;

  /* Create a bar indicator style */
  static lv_style_t style_bar_indic;
  lv_style_copy(&style_bar_indic, &lv_style_pretty);
  style_bar_indic.body.radius = 3;
  style_bar_indic.body.main_color = LV_COLOR_GRAY;          /*White main color*/
  style_bar_indic.body.grad_color = LV_COLOR_GRAY;           /*Blue gradient color*/
  style_bar_indic.body.border.width = 0;                     /*2 px border width*/
  style_bar_indic.body.padding.left = 8;
  style_bar_indic.body.padding.right = 8;
  style_bar_indic.body.padding.top = 8;
  style_bar_indic.body.padding.bottom = 8;

  /*Create a bar and apply the styles*/
  lv_obj_t * bar = lv_bar_create(scr, NULL);
  lv_bar_set_style(bar, LV_BAR_STYLE_BG, &style_bar_bg);
  lv_bar_set_style(bar, LV_BAR_STYLE_INDIC, &style_bar_indic);
  lv_bar_set_value(bar, 70, false);
  lv_obj_set_size(bar, 200, 30);
  lv_obj_align(bar, obj1, LV_ALIGN_OUT_BOTTOM_LEFT, 0, 20);

}


void loop() {

  lv_task_handler(); /* let the GUI do its work */
  delay(5);
}
