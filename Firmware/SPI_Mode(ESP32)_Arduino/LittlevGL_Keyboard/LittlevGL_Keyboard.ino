#include <lvgl.h>
#include <Ticker.h>
#include <TFT_eSPI.h>

#define LVGL_TICK_PERIOD 20

Ticker tick; /* timer for interrupt handler */

TFT_eSPI tft = TFT_eSPI(); /* TFT instance */
static lv_disp_buf_t disp_buf;
static lv_color_t buf[LV_HOR_RES_MAX * 10];

static lv_obj_t * btn_enable;           /*An enable button*/
static lv_style_t style_mbox_bg;        /*Black bg. style with opacity*/
static lv_group_t * g;                  /*An Object Group*/
static lv_indev_t * emulated_kp_indev;  /*The input device of the emulated keypad*/
static lv_indev_state_t last_state = LV_INDEV_STATE_REL;
static uint32_t last_key = 0;


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

  lv_tutorial_keyboard(NULL);

}

/**
 * Create a simple GUI to demonstrate encoder control capability
 * kp_indev optinonally pass a keypad input device to control the object (NULL if unused)
 */
void lv_tutorial_keyboard(lv_indev_t * kp_indev)
{
    /*Register the emulated keyboard*/
    lv_indev_drv_t  kp_drv;
    lv_indev_drv_init(&kp_drv);
    kp_drv.type = LV_INDEV_TYPE_KEYPAD;
    kp_drv.read_cb = emulated_keypad_read;
    emulated_kp_indev = lv_indev_drv_register(&kp_drv);

    /*Create an object group*/
    g = lv_group_create();

    /*Assig the input device(s) to the created group*/
    lv_indev_set_group(emulated_kp_indev, g);
    if(kp_indev) lv_indev_set_group(kp_indev, g);

    /*Create a demo GUI*/
    gui_create();

    /*Create virtual encoder*/
    kaypad_create();
}

/**
 * Create a demo GUI
 */
static void gui_create(void)
{
    lv_obj_t * scr = lv_disp_get_scr_act(NULL);     /*Get the current screen*/

    /*Create a drop down list*/
    lv_obj_t * ddlist = lv_ddlist_create(scr, NULL);
    lv_ddlist_set_options(ddlist, "Low\nMedium\nHigh");
    lv_obj_set_pos(ddlist, LV_DPI / 4, LV_DPI / 4);
    lv_group_add_obj(g, ddlist);                    /*Add the object to the group*/

    /*Create a holder and check boxes on it*/
    lv_obj_t * holder = lv_cont_create(scr, NULL);   /*Create a transparent holder*/
    lv_cont_set_fit(holder, LV_FIT_TIGHT);

    lv_cont_set_layout(holder, LV_LAYOUT_COL_L);
    lv_obj_set_style(holder, &lv_style_transp);
    lv_obj_align(holder, ddlist, LV_ALIGN_OUT_RIGHT_TOP, LV_DPI / 4, 0);

    lv_obj_t * cb = lv_cb_create(holder, NULL);     /*First check box*/
    lv_cb_set_text(cb, "Red");
    lv_group_add_obj(g, cb);                        /*Add to the group*/

    cb = lv_cb_create(holder, cb);                  /*Copy the first check box. Automatically added to the same group*/
    lv_cb_set_text(cb, "Green");

    cb = lv_cb_create(holder, cb);                  /*Copy the second check box. Automatically added to the same group*/
    lv_cb_set_text(cb, "Blue");

    /*Create a sliders*/
    lv_obj_t * slider = lv_slider_create(scr, NULL);
    lv_obj_set_size(slider, LV_DPI, LV_DPI / 3);
    lv_obj_align(slider, holder, LV_ALIGN_OUT_RIGHT_TOP, LV_DPI / 4, 0);
    lv_bar_set_range(slider, 0, 20);
    lv_group_add_obj(g, slider);                    /*Add to the group*/

    /*Create a button*/
    btn_enable = lv_btn_create(scr, NULL);
    lv_obj_set_event_cb(btn_enable, message_btn_event_cb);
    lv_btn_set_fit(btn_enable, LV_FIT_TIGHT);
    lv_group_add_obj(g, btn_enable);                /*Add to the group*/
    lv_obj_t * l = lv_label_create(btn_enable, NULL);
    lv_label_set_text(l, "Message");
    lv_obj_align(btn_enable, slider, LV_ALIGN_OUT_BOTTOM_MID, 0, LV_DPI / 2);

    /* Create a dark plain style for a message box's background (modal)*/
    lv_style_copy(&style_mbox_bg, &lv_style_plain);
    style_mbox_bg.body.main_color = LV_COLOR_BLACK;
    style_mbox_bg.body.grad_color = LV_COLOR_BLACK;
    style_mbox_bg.body.opa = LV_OPA_50;
}

/**
 * Create virtual keypad using 4 buttons:
 * - Next: focus on the next object in the group
 * - Increment: increment the object value
 * - Decrement: decrement the object value
 * - Enter: Select something
 */
static void kaypad_create(void)
{
    lv_obj_t * scr = lv_disp_get_scr_act(NULL);     /*Get the current screen*/

    /*Next button*/
    lv_obj_t * btn_next = lv_btn_create(scr, NULL);
    lv_obj_set_event_cb(btn_next, keypad_event_cb);
    lv_btn_set_fit(btn_next, LV_FIT_TIGHT);
    lv_obj_t * l = lv_label_create(btn_next, NULL);
    lv_label_set_text(l, "Next");
    lv_obj_align(btn_next, NULL, LV_ALIGN_IN_BOTTOM_LEFT, LV_DPI / 4, - LV_DPI / 4);

    /*Increment button*/
    lv_obj_t * btn_inc = lv_btn_create(scr, btn_next);
    l = lv_label_create(btn_inc, NULL);
    lv_label_set_text(l, "Dec");
    lv_obj_align(btn_inc, btn_next, LV_ALIGN_OUT_RIGHT_MID, LV_DPI / 4, 0);

    /*Decrement button*/
    lv_obj_t * btn_dec = lv_btn_create(scr, btn_next);
    l = lv_label_create(btn_dec, NULL);
    lv_label_set_text(l, "Inc");
    lv_obj_align(btn_dec, btn_inc, LV_ALIGN_OUT_RIGHT_MID, LV_DPI / 4, 0);

    /*Enter button*/
    lv_obj_t * btn_enter = lv_btn_create(scr, btn_next);
    l = lv_label_create(btn_enter, NULL);
    lv_label_set_text(l, "Enter");
    lv_obj_align(btn_enter, btn_dec, LV_ALIGN_OUT_RIGHT_MID, LV_DPI / 4, 0);
}

static bool emulated_keypad_read(lv_indev_drv_t * indev_drv, lv_indev_data_t * data)
{
    (void)indev_drv;                /*Unused*/
    data->key = last_key;
    data->state = last_state;
    return false;
}

/**
 * Called when the Enable button is released. Show a message box to really enable or not?
 * @param btn pointer to the Enable button
 * @param indev_proc pointer to the caller display input or NULL if the encoder used
 * @return LV_RES_OK: because the button is not deleted
 */
static void message_btn_event_cb(lv_obj_t * btn, lv_event_t event)
{
    if(event != LV_EVENT_RELEASED) return;  /*We only care only with the release event*/

    /*If the butto nsi released the show message box to be sure about the Enable*/
    if(lv_btn_get_state(btn) == LV_BTN_STATE_REL) {
        /* Create a dark screen sized bg. with opacity to show
         * the other objects are not available now*/
        lv_obj_set_style(lv_disp_get_layer_top(NULL), &style_mbox_bg);
        lv_obj_set_click(lv_disp_get_layer_top(NULL), false);     /*It should be `true` but it'd block the emulated keyboard too*/

        /*Create a message box*/
        lv_obj_t * mbox = lv_mbox_create(lv_disp_get_layer_top(NULL), NULL);
        lv_mbox_set_text(mbox, "Turn on something?");
        lv_obj_set_event_cb(mbox, mbox_event_cb);
        lv_group_add_obj(g, mbox);          /*Add to he group*/

        /*Add two buttons*/
        static const char * btns[] = {"Yes", "No", ""};
        lv_mbox_add_btns(mbox, btns);

        lv_obj_align(mbox, NULL, LV_ALIGN_CENTER, 0, - LV_DPI / 2);

        /*Focus on the new message box, can freeze focus on it*/
        lv_group_focus_obj(mbox);
        lv_group_focus_freeze(g, true);
    }
    /*Just disable without message*/
    else {
        lv_btn_set_state(btn_enable, LV_BTN_STATE_REL);
    }
}

/**
 * Called when a message box button is clicked
 * @param mbox pointer to message box
 * @param event event type
 */
static void mbox_event_cb(lv_obj_t * mbox, lv_event_t event)
{
    if(event != LV_EVENT_CLICKED) return;

    const char * btn_txt = lv_mbox_get_active_btn_text(mbox);
    if(btn_txt) {
        lv_group_focus_freeze(g, false);        /*Release the freeze*/

        /*Revert the top layer to not block*/
        lv_obj_set_style(lv_disp_get_layer_top(NULL), &lv_style_transp);
        lv_obj_set_click(lv_disp_get_layer_top(NULL), false);

        /*Mark the enabled state by toggling the button*/
        if(strcmp(btn_txt, "No") == 0)  lv_btn_set_state(btn_enable, LV_BTN_STATE_REL);
        else if(strcmp(btn_txt, "Yes") == 0)  lv_btn_set_state(btn_enable, LV_BTN_STATE_TGL_REL);

        lv_obj_del(mbox);
    }
}

/**
 * Called the handle the emulated keys' events
 * @param btn pointer to the button
 * @return LV_RES_OK: because the button is not deleted
 */
static void keypad_event_cb(lv_obj_t * btn, lv_event_t event)
{
    if(event == LV_EVENT_PRESSED) {

        lv_obj_t * label = lv_obj_get_child(btn, NULL);
        const char * txt = lv_label_get_text(label);

        if(strcmp(txt, "Next") == 0)        last_key = LV_KEY_NEXT;
        else if (strcmp(txt, "Inc") == 0)   last_key = LV_KEY_UP;
        else if (strcmp(txt, "Dec") == 0)   last_key = LV_KEY_DOWN;
        else if (strcmp(txt, "Enter") == 0) last_key = LV_KEY_ENTER;
        else last_key = 0;

        last_state = LV_INDEV_STATE_PR;         /*Save the state*/
    } else if(event == LV_EVENT_RELEASED || event == LV_EVENT_PRESS_LOST) {
        last_state = LV_INDEV_STATE_REL;
    }

}

void loop() {

  lv_task_handler(); /* let the GUI do its work */
  delay(5);
}
