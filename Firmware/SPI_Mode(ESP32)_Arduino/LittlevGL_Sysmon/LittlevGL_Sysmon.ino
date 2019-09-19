#include <lvgl.h>
#include <Ticker.h>
#include <TFT_eSPI.h>

#define LVGL_TICK_PERIOD 20

#define CPU_LABEL_COLOR     "FF0000"
#define MEM_LABEL_COLOR     "0000FF"
#define CHART_POINT_NUM     100
#define REFR_TIME    500

Ticker tick; /* timer for interrupt handler */

TFT_eSPI tft = TFT_eSPI(); /* TFT instance */
static lv_disp_buf_t disp_buf;
static lv_color_t buf[LV_HOR_RES_MAX * 10];

static lv_obj_t * win;
static lv_obj_t * chart;
static lv_chart_series_t * cpu_ser;
static lv_chart_series_t * mem_ser;
static lv_obj_t * info_label;
static lv_task_t * refr_task;


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

  sysmon_create();

}

/**
 * Initialize the system monitor
 */
void sysmon_create(void)
{
    refr_task = lv_task_create(sysmon_task, REFR_TIME, LV_TASK_PRIO_LOW, NULL);


    lv_coord_t hres = lv_disp_get_hor_res(NULL);
    lv_coord_t vres = lv_disp_get_ver_res(NULL);

    win = lv_win_create(lv_disp_get_scr_act(NULL), NULL);
    lv_obj_t * win_btn = lv_win_add_btn(win, LV_SYMBOL_CLOSE);
    lv_obj_set_event_cb(win_btn, win_close_action);

    /*Make the window content responsive*/
    lv_win_set_layout(win, LV_LAYOUT_PRETTY);

    /*Create a chart with two data lines*/
    chart = lv_chart_create(win, NULL);
    lv_obj_set_size(chart, hres / 2, vres / 2);
    lv_obj_set_pos(chart, LV_DPI / 10, LV_DPI / 10);
    lv_chart_set_point_count(chart, CHART_POINT_NUM);
    lv_chart_set_range(chart, 0, 100);
    lv_chart_set_type(chart, LV_CHART_TYPE_LINE);
    lv_chart_set_series_width(chart, 4);
    cpu_ser =  lv_chart_add_series(chart, LV_COLOR_RED);
    mem_ser =  lv_chart_add_series(chart, LV_COLOR_BLUE);

    /*Set the data series to zero*/
    uint16_t i;
    for(i = 0; i < CHART_POINT_NUM; i++) {
        lv_chart_set_next(chart, cpu_ser, 0);
        lv_chart_set_next(chart, mem_ser, 0);
    }

    /*Create a label for the details of Memory and CPU usage*/
    info_label = lv_label_create(win, NULL);
    lv_label_set_recolor(info_label, true);
    lv_obj_align(info_label, chart, LV_ALIGN_OUT_RIGHT_TOP, LV_DPI / 4, 0);

    /*Refresh the chart and label manually at first*/
    sysmon_task(NULL);
}

/**********************
 *   STATIC FUNCTIONS
 **********************/

/**
 * Called periodically to monitor the CPU and memory usage.
 * @param param unused
 */
static void sysmon_task(lv_task_t * param)
{

    (void) param;    /*Unused*/

    LV_LOG_TRACE("sys_mon task started");

    /*Get CPU and memory information */
    uint8_t cpu_busy;
    cpu_busy = 100 - lv_task_get_idle();

    uint8_t mem_used_pct = 0;
#if  LV_MEM_CUSTOM == 0
    lv_mem_monitor_t mem_mon;
    lv_mem_monitor(&mem_mon);
    mem_used_pct = mem_mon.used_pct;
#endif

    /*Add the CPU and memory data to the chart*/
    lv_chart_set_next(chart, cpu_ser, cpu_busy);
    lv_chart_set_next(chart, mem_ser, mem_used_pct);

    /*Refresh the and windows*/
    char buf_long[256];
    sprintf(buf_long, "%s%s CPU: %d %%%s\n\n",
            LV_TXT_COLOR_CMD,
            CPU_LABEL_COLOR,
            cpu_busy,
            LV_TXT_COLOR_CMD);

#if LV_MEM_CUSTOM == 0
    sprintf(buf_long, "%s"LV_TXT_COLOR_CMD"%s MEMORY: %d %%"LV_TXT_COLOR_CMD"\n"
            "Total: %d bytes\n"
            "Used: %d bytes\n"
            "Free: %d bytes\n"
            "Frag: %d %%",
            buf_long,
            MEM_LABEL_COLOR,
            mem_used_pct,
            (int)mem_mon.total_size,
            (int)mem_mon.total_size - mem_mon.free_size, mem_mon.free_size, mem_mon.frag_pct);

#else
    sprintf(buf_long, "%s"LV_TXT_COLOR_CMD"%s MEMORY: N/A"LV_TXT_COLOR_CMD,
            buf_long,
            MEM_LABEL_COLOR);
#endif
    lv_label_set_text(info_label, buf_long);


    LV_LOG_TRACE("sys_mon task finished");
}

/**
 * Called when the window's close button is clicked
 * @param btn pointer to the close button
 * @param event the current event
 */
static void win_close_action(lv_obj_t * btn, lv_event_t event)
{
    (void) btn;    /*Unused*/

    if(event != LV_EVENT_CLICKED) return;

    lv_obj_del(win);
    win = NULL;

    lv_task_del(refr_task);
    refr_task = NULL;
}

void loop() {

  // Normal Tasks
  for(uint32_t i = 0; i < 1000; i++) {
    lv_task_handler(); /* let the GUI do its work */
    delay(5);
  }

  // High CPU Load Tasks
  for(uint32_t i = 0; i < 1000000; i++) {
    lv_task_handler();
    volatile uint32_t test;
    test = i*i*i;
    test = test + test;
    for (uint32_t t = 0; t < 1000000; t++){};
  }

}
